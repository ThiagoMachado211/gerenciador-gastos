import hashlib
from datetime import timedelta
from django.contrib import messages
from django.contrib.auth import authenticate, login, logout, update_session_auth_hash
from django.contrib.auth.decorators import login_required
from django.contrib.auth.forms import PasswordChangeForm
from django.contrib.auth.views import PasswordResetView
from django.core.paginator import Paginator
from django.db import transaction
from django.db.models import Sum
from django.http import HttpResponse, HttpResponseForbidden
from django.shortcuts import get_object_or_404, redirect, render
from django.utils import timezone
from django.views.decorators.http import require_POST
from .forms import RegistrationForm, ProfileForm, CategoryForm, CreditCardForm, TransactionForm
from .models import User, Category, CreditCard, Transaction, RateLimit


def limited(request, action, limit=20):
    # Trust only the direct peer. The deployment proxy must rate-limit before forwarding.
    key = hashlib.sha256(f"{action}:{request.META.get('REMOTE_ADDR', '')}".encode()).hexdigest()
    now = timezone.now()
    with transaction.atomic():
        row, _ = RateLimit.objects.get_or_create(key=key, defaults={'expires_at': now + timedelta(minutes=15)})
        row = RateLimit.objects.select_for_update().get(pk=key)
        if row.expires_at <= now:
            row.count, row.expires_at = 0, now + timedelta(minutes=15)
        row.count += 1
        row.save()
        return row.count > limit


def home(request):
    return render(request, 'home.html')


def pricing(request):
    return render(request, 'pricing.html')


def sign_in(request):
    error = None
    if request.method == 'POST':
        if limited(request, 'login'):
            return HttpResponse('Muitas tentativas. Aguarde 15 minutos.', status=429)
        email = request.POST.get('email', '').strip().lower()
        with transaction.atomic():
            account = User.objects.select_for_update().filter(email__iexact=email).first()
            locked = account and account.locked_until and account.locked_until > timezone.now()
            user = authenticate(request, username=account.username if account else email, password=request.POST.get('password', ''))
            if user and not locked:
                account.failed_attempts, account.locked_until = 0, None
                account.save(update_fields=['failed_attempts', 'locked_until'])
                login(request, user)
                if not request.POST.get('remember'):
                    request.session.set_expiry(0)
                return redirect('dashboard')
            if account and not locked:
                account.failed_attempts += 1
                if account.failed_attempts >= 5:
                    account.locked_until = timezone.now() + timedelta(minutes=30)
                    account.failed_attempts = 0
                account.save(update_fields=['failed_attempts', 'locked_until'])
        error = 'E-mail ou senha inválidos, ou conta temporariamente bloqueada.'
    return render(request, 'login.html', {'error': error})


def register(request):
    if request.method == 'POST' and limited(request, 'register', 5):
        return HttpResponse('Muitas tentativas. Aguarde 15 minutos.', status=429)
    form = RegistrationForm(request.POST or None)
    if request.method == 'POST' and form.is_valid():
        user = form.save()
        login(request, user)
        return redirect('dashboard')
    return render(request, 'form.html', {'form': form, 'title': 'Criar conta gratuita'})


class LimitedPasswordResetView(PasswordResetView):
    template_name = 'form.html'
    email_template_name = 'registration/password_reset_email.html'
    subject_template_name = 'registration/password_reset_subject.txt'
    success_url = '/users/password/sent'
    extra_context = {'title': 'Recuperar senha'}

    def post(self, request, *args, **kwargs):
        if limited(request, 'password-reset', 5):
            return HttpResponse('Muitas tentativas. Aguarde 15 minutos.', status=429)
        return super().post(request, *args, **kwargs)


@require_POST
def sign_out(request):
    logout(request)
    return redirect('home')


@login_required
def profile(request):
    form = ProfileForm(request.POST or None, instance=request.user)
    if request.method == 'POST' and form.is_valid():
        form.save()
        messages.success(request, 'Conta atualizada.')
        return redirect('profile')
    return render(request, 'form.html', {'form': form, 'title': 'Minha conta', 'profile': True})


@login_required
def password_change(request):
    form = PasswordChangeForm(request.user, request.POST or None)
    if request.method == 'POST' and form.is_valid():
        user = form.save()
        update_session_auth_hash(request, user)
        messages.success(request, 'Senha atualizada.')
        return redirect('profile')
    return render(request, 'form.html', {'form': form, 'title': 'Alterar senha'})


@login_required
def delete_account(request):
    if request.method == 'POST':
        if request.user.check_password(request.POST.get('password', '')):
            user = request.user
            logout(request)
            user.delete()
            return redirect('home')
        messages.error(request, 'Senha inválida.')
    return render(request, 'delete_account.html')


def totals(query):
    income = query.filter(kind='income').aggregate(n=Sum('amount_cents'))['n'] or 0
    expense = query.filter(kind='expense').aggregate(n=Sum('amount_cents'))['n'] or 0
    return {'income': income, 'expense': expense, 'balance': income - expense}


@login_required
def dashboard(request):
    today = timezone.localdate()
    query = Transaction.objects.filter(user=request.user)
    year = query.filter(occurred_on__year=today.year)
    summary = totals(query.filter(occurred_on__year=today.year, occurred_on__month=today.month))
    months = []
    names = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez']
    grouped = year.values('occurred_on__month', 'kind').annotate(total=Sum('amount_cents'))
    values = {(r['occurred_on__month'], r['kind']): r['total'] for r in grouped}
    for i, name in enumerate(names, 1):
        months.append({'name': name, 'income': values.get((i, 'income'), 0), 'expense': values.get((i, 'expense'), 0)})
    categories = year.filter(kind='expense', category__isnull=False).values('category__name').annotate(total=Sum('amount_cents')).order_by('-total')
    return render(request, 'dashboard.html', {'summary': summary, 'year_summary': totals(year), 'year': today.year,
        'recent': query.select_related('category', 'credit_card').order_by('-occurred_on', '-id')[:8], 'months': months, 'categories': categories})


RESOURCES = {'categories': (Category, CategoryForm, 'Categorias', 4),
             'credit_cards': (CreditCard, CreditCardForm, 'Cartões', 1),
             'transactions': (Transaction, TransactionForm, 'Transações', None)}


@login_required
def resource_list(request, resource):
    model, _, title, limit = RESOURCES[resource]
    query = model.objects.filter(user=request.user)
    summary = totals(query) if resource == 'transactions' else None
    if resource == 'transactions':
        query = query.select_related('category', 'credit_card').order_by('-occurred_on', '-id')
    else:
        query = query.order_by('name', 'id')
    page = Paginator(query, 25).get_page(request.GET.get('page'))
    return render(request, 'list.html', {'page': page, 'resource': resource, 'title': title, 'limit': limit, 'summary': summary})


@login_required
def resource_form(request, resource, pk=None):
    model, form_class, title, limit = RESOURCES[resource]
    instance = get_object_or_404(model, pk=pk, user=request.user) if pk else model(user=request.user)
    kwargs = {'user': request.user} if resource == 'transactions' else {}
    form = form_class(request.POST or None, instance=instance, **kwargs)
    if request.method == 'POST' and form.is_valid():
        with transaction.atomic():
            # Serialize quota checks for a single account on PostgreSQL.
            User.objects.select_for_update().get(pk=request.user.pk)
            if not pk and limit and model.objects.filter(user=request.user).count() >= limit:
                form.add_error(None, f'O plano gratuito permite até {limit} registro(s) nesta seção.')
            else:
                record = form.save(commit=False)
                record.user = request.user
                record.save()
                messages.success(request, 'Registro salvo.')
                return redirect(f'/{"users"}/{resource}')
    return render(request, 'form.html', {'form': form, 'title': ('Editar ' if pk else 'Adicionar · ') + title})


@login_required
def resource_delete(request, resource, pk):
    model = RESOURCES[resource][0]
    instance = get_object_or_404(model, pk=pk, user=request.user)
    if request.method == 'POST':
        instance.delete()
        messages.success(request, 'Registro excluído.')
        return redirect(f'/users/{resource}')
    return render(request, 'confirm_delete.html', {'record': instance})


@login_required
def subscription(request):
    return render(request, 'pricing.html')


@login_required
def admin_dashboard(request):
    if not request.user.is_staff:
        return HttpResponseForbidden('Acesso restrito a administradores.')
    users = User.objects.order_by('-date_joined', '-id')
    page = Paginator(users, 25).get_page(request.GET.get('page'))
    return render(request, 'admin.html', {'page': page, 'count': users.count(), 'admins': users.filter(is_staff=True).count(),
        'new_users': users.filter(date_joined__gte=timezone.now() - timedelta(days=30)).count()})
