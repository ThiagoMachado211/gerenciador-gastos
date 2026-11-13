from django import forms
from django.contrib.auth.forms import UserCreationForm
from django.utils import timezone
from .models import User, Category, CreditCard, Transaction


class RegistrationForm(UserCreationForm):
    class Meta:
        model = User
        fields = ('name', 'email')

    def clean_email(self):
        email = self.cleaned_data['email'].strip().lower()
        if User.objects.filter(email__iexact=email).exists():
            raise forms.ValidationError('Não foi possível cadastrar este e-mail.')
        return email

    def save(self, commit=True):
        user = super().save(commit=False)
        user.username = self.cleaned_data['email']
        if commit:
            user.save()
        return user


class ProfileForm(forms.ModelForm):
    class Meta:
        model = User
        fields = ('name',)


class CategoryForm(forms.ModelForm):
    class Meta:
        model = Category
        fields = ('name', 'color', 'icon')


class CreditCardForm(forms.ModelForm):
    class Meta:
        model = CreditCard
        fields = ('name', 'limit_cents', 'closing_day', 'due_day')


class TransactionForm(forms.ModelForm):
    class Meta:
        model = Transaction
        fields = ('kind', 'description', 'amount_cents', 'occurred_on', 'installments_count', 'category', 'credit_card')
        widgets = {'occurred_on': forms.DateInput(attrs={'type': 'date'}, format='%Y-%m-%d')}

    def __init__(self, *args, user, **kwargs):
        super().__init__(*args, **kwargs)
        self.instance.user = user
        if not self.instance.pk:
            self.initial.setdefault('kind', 'expense')
            self.initial.setdefault('occurred_on', timezone.localdate())
            self.initial.setdefault('installments_count', 1)
        self.fields['category'].queryset = Category.objects.filter(user=user).order_by('name')
        self.fields['credit_card'].queryset = CreditCard.objects.filter(user=user).order_by('name')
