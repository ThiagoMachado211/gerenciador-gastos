import io
import os
from datetime import timedelta
from unittest.mock import patch, MagicMock
import bcrypt
from django.contrib.auth import get_user_model
from django.contrib.auth.hashers import check_password
from django.core import mail
from django.core.exceptions import ValidationError
from django.core.management import call_command
from django.core.management.base import CommandError
from django.test import TestCase, Client, override_settings
from django.utils import timezone
from .models import Category, CreditCard, Transaction, RateLimit
from .templatetags.money import money

User = get_user_model()
PASSWORD = 'UmaSenhaDeTeste!5739'

class ApplicationTests(TestCase):
    @classmethod
    def setUpTestData(cls):
        cls.user = User.objects.create_user('ana@example.com', 'ana@example.com', PASSWORD, name='Ana')
        cls.other = User.objects.create_user('bia@example.com', 'bia@example.com', PASSWORD)

    def login(self):
        self.client.force_login(self.user)

    def test_public_pages_and_protected_routes(self):
        for url in ['/', '/public/planos-pagos', '/users/sign_in', '/users/sign_up', '/users/password/new', '/up']:
            self.assertEqual(self.client.get(url).status_code, 200, url)
        for url in ['/users/dashboard', '/users/categories', '/users/credit_cards', '/users/transactions', '/admin']:
            self.assertEqual(self.client.get(url).status_code, 302, url)
        self.assertEqual(self.client.post('/webhooks/stripe').status_code, 404)

    def test_registration_and_login(self):
        result = self.client.post('/users/sign_up', {'name': 'Nova', 'email': 'NOVA@example.com', 'password1': PASSWORD, 'password2': PASSWORD, 'is_staff': 'true'})
        self.assertEqual(result.status_code, 302)
        user = User.objects.get(email='nova@example.com')
        self.assertFalse(user.is_staff)
        self.assertTrue(user.check_password(PASSWORD))
        self.client.post('/users/sign_out')
        self.assertEqual(self.client.post('/users/sign_in', {'email': 'NOVA@example.com', 'password': PASSWORD}).status_code, 302)
        self.assertEqual(self.client.get('/users/sign_out').status_code, 405)

    def test_weak_password_and_duplicate_email_rejected(self):
        self.client.post('/users/sign_up', {'email': 'weak@example.com', 'password1': 'abc', 'password2': 'abc'})
        self.assertFalse(User.objects.filter(email='weak@example.com').exists())
        result = self.client.post('/users/sign_up', {'email': 'ANA@example.com', 'password1': PASSWORD, 'password2': PASSWORD})
        self.assertEqual(result.status_code, 200)
        self.assertEqual(User.objects.count(), 2)

    def test_authenticated_pages_render(self):
        self.login()
        for url in ['/users/dashboard', '/users/transactions', '/users/categories', '/users/credit_cards', '/users/subscription', '/users/edit', '/users/password/change', '/users/delete', '/users/categories/new', '/users/credit_cards/new', '/users/transactions/new']:
            self.assertEqual(self.client.get(url).status_code, 200, url)

    def test_category_crud_and_limit(self):
        self.login()
        for i in range(4):
            self.assertEqual(self.client.post('/users/categories/new', {'name': f'Categoria {i}', 'color': '#30d988'}).status_code, 302)
        result = self.client.post('/users/categories/new', {'name': 'Quinta'})
        self.assertContains(result, 'plano gratuito')
        self.assertEqual(Category.objects.filter(user=self.user).count(), 4)
        category = Category.objects.filter(user=self.user).first()
        self.client.post(f'/users/categories/{category.pk}/edit', {'name': 'Renomeada'})
        category.refresh_from_db()
        self.assertEqual(category.name, 'Renomeada')
        self.client.post(f'/users/categories/{category.pk}/delete')
        self.assertEqual(Category.objects.filter(user=self.user).count(), 3)

    def test_card_validation_and_limit(self):
        self.login()
        self.client.post('/users/credit_cards/new', {'name': 'Inválido', 'limit_cents': -1, 'closing_day': 32, 'due_day': 0})
        self.assertEqual(CreditCard.objects.count(), 0)
        payload = {'name': 'Cartão', 'limit_cents': 100000, 'closing_day': 5, 'due_day': 15}
        self.assertEqual(self.client.post('/users/credit_cards/new', payload).status_code, 302)
        self.client.post('/users/credit_cards/new', payload)
        self.assertEqual(CreditCard.objects.count(), 1)

    def test_cross_account_access_and_foreign_keys(self):
        self.login()
        other = Category.objects.create(user=self.other, name='Privada')
        for suffix in ['edit', 'delete']:
            self.assertEqual(self.client.get(f'/users/categories/{other.pk}/{suffix}').status_code, 404)
            self.assertEqual(self.client.post(f'/users/categories/{other.pk}/{suffix}', {'name': 'Invadida'}).status_code, 404)
        payload = self.payload(category=other.pk)
        self.client.post('/users/transactions/new', payload)
        self.assertEqual(Transaction.objects.count(), 0)
        card = CreditCard.objects.create(user=self.other, name='Privado', limit_cents=0, closing_day=1, due_day=2)
        self.client.post('/users/transactions/new', self.payload(credit_card=card.pk))
        self.assertEqual(Transaction.objects.count(), 0)

    def payload(self, **extra):
        return {'description': 'Compra', 'kind': 'expense', 'amount_cents': 12550, 'occurred_on': timezone.localdate().isoformat(), 'installments_count': 1, **extra}

    def test_transactions_summary_edit_delete_and_nullify(self):
        self.login()
        category = Category.objects.create(user=self.user, name='Mercado')
        self.client.post('/users/transactions/new', self.payload(category=category.pk))
        self.client.post('/users/transactions/new', self.payload(kind='income', amount_cents=20000))
        result = self.client.get('/users/dashboard')
        self.assertEqual(result.context['summary'], {'income': 20000, 'expense': 12550, 'balance': 7450})
        self.assertEqual(len(result.context['months']), 12)
        self.assertContains(result, 'R$ 125,50')
        self.client.post(f'/users/categories/{category.pk}/delete')
        record = Transaction.objects.get(kind='expense')
        self.assertIsNone(record.category)
        self.client.post(f'/users/transactions/{record.pk}/edit', self.payload(amount_cents=100))
        record.refresh_from_db()
        self.assertEqual(record.amount_cents, 100)
        self.client.post(f'/users/transactions/{record.pk}/delete')
        self.assertEqual(Transaction.objects.count(), 1)

    def test_invalid_financial_fields(self):
        self.login()
        for extra in [{'amount_cents': 0}, {'amount_cents': 2147483648}, {'amount_cents': '1.5'}, {'kind': 'bad'}, {'occurred_on': '2026-99-99'}, {'installments_count': 37}]:
            self.client.post('/users/transactions/new', self.payload(**extra))
        self.assertEqual(Transaction.objects.count(), 0)

    def test_admin_permissions_and_pagination(self):
        self.login()
        self.assertEqual(self.client.get('/admin').status_code, 403)
        self.user.is_staff = True
        self.user.save()
        self.assertContains(self.client.get('/admin'), 'ana@example.com')
        self.assertEqual(self.client.get('/admin/users?page=abc').status_code, 200)

    def test_account_lock_and_ip_limit(self):
        for _ in range(5):
            self.client.post('/users/sign_in', {'email': self.user.email, 'password': 'wrong'})
        self.user.refresh_from_db()
        self.assertGreater(self.user.locked_until, timezone.now())
        self.assertEqual(self.client.post('/users/sign_in', {'email': self.user.email, 'password': PASSWORD}).status_code, 200)
        self.user.locked_until = timezone.now() - timedelta(seconds=1)
        self.user.save()
        self.assertEqual(self.client.post('/users/sign_in', {'email': self.user.email, 'password': PASSWORD}).status_code, 302)
        for _ in range(20):
            result = self.client.post('/users/sign_in', {'email': 'none@example.com', 'password': 'wrong'})
        self.assertEqual(result.status_code, 429)

    def test_csrf_and_security_headers(self):
        client = Client(enforce_csrf_checks=True)
        self.assertEqual(client.post('/users/sign_in', {'email': self.user.email}).status_code, 403)
        response = self.client.get('/')
        self.assertIn("script-src 'self'", response['Content-Security-Policy'])
        self.assertEqual(response['X-Content-Type-Options'], 'nosniff')
        self.login()
        self.assertEqual(self.client.get('/users/dashboard')['Cache-Control'], 'no-store')

    @override_settings(EMAIL_BACKEND='django.core.mail.backends.locmem.EmailBackend')
    def test_password_reset_flow_and_rate_limit(self):
        self.client.post('/users/password/new', {'email': self.user.email})
        self.assertEqual(len(mail.outbox), 1)
        link = next(line for line in mail.outbox[0].body.splitlines() if line.startswith('http'))
        from urllib.parse import urlparse
        response = self.client.get(urlparse(link).path)
        response = self.client.post(response.url, {'new_password1': 'OutraSenhaForte!8793', 'new_password2': 'OutraSenhaForte!8793'})
        self.assertEqual(response.status_code, 302)
        self.user.refresh_from_db()
        self.assertTrue(self.user.check_password('OutraSenhaForte!8793'))
        for _ in range(5):
            response = self.client.post('/users/password/new', {'email': 'unknown@example.com'})
        self.assertEqual(response.status_code, 429)

    def test_delete_account_requires_password(self):
        self.login()
        Category.objects.create(user=self.user, name='Excluir')
        self.client.post('/users/delete', {'password': 'bad'})
        self.assertTrue(User.objects.filter(pk=self.user.pk).exists())
        self.client.post('/users/delete', {'password': PASSWORD})
        self.assertFalse(User.objects.filter(pk=self.user.pk).exists())
        self.assertFalse(Category.objects.exists())

    def test_imported_bcrypt_and_long_password(self):
        for password in [PASSWORD, 'Abc!123' * 16]:
            hashed = bcrypt.hashpw(password.encode()[:72], bcrypt.gensalt(rounds=4)).decode()
            self.assertTrue(check_password(password, 'bcrypt$' + hashed))
            self.assertFalse(check_password('incorrect', 'bcrypt$' + hashed))

    def test_admin_creation_refuses_weak_or_existing_accounts(self):
        with patch.dict(os.environ, {'ADMIN_EMAIL': 'admin@example.com', 'ADMIN_PASSWORD': PASSWORD}):
            with self.assertRaises(CommandError):
                call_command('create_admin', stdout=io.StringIO())
        strong = 'UmaSenhaAdministrativaMuitoForte!6739'
        with patch.dict(os.environ, {'ADMIN_EMAIL': self.user.email, 'ADMIN_PASSWORD': strong}):
            with self.assertRaises(CommandError):
                call_command('create_admin', stdout=io.StringIO())
        with patch.dict(os.environ, {'ADMIN_EMAIL': 'admin@example.com', 'ADMIN_PASSWORD': strong}):
            call_command('create_admin', stdout=io.StringIO())
        self.assertTrue(User.objects.get(email='admin@example.com').is_staff)

    def test_money(self):
        self.assertEqual(money(123456789), 'R$ 1.234.567,89')
        self.assertEqual(money(-123), '-R$ 1,23')


class ImportTests(TestCase):
    def source(self, invalid=False):
        now = timezone.now()
        hashed = bcrypt.hashpw(PASSWORD.encode(), bcrypt.gensalt(rounds=4)).decode()
        rows = {
            'users': [{'id': 50, 'email': 'old@example.com', 'name': 'Antigo', 'admin': False, 'created_at': now, 'encrypted_password': hashed}],
            'categories': [{'id': 20, 'user_id': 50, 'name': 'Mercado', 'color': '', 'icon': '', 'created_at': now, 'updated_at': now}],
            'credit_cards': [],
            'transactions': [{'id': 77, 'user_id': 50, 'category_id': 20, 'credit_card_id': None, 'description': 'Antiga', 'amount_cents': -1 if invalid else 123, 'kind': 'expense', 'occurred_on': now.date(), 'installments_count': 1, 'created_at': now, 'updated_at': now}],
        }
        connection = MagicMock()
        def execute(sql):
            result = MagicMock()
            result.fetchall.return_value = rows.get(sql.split()[-1], [])
            return result
        connection.execute.side_effect = execute
        return connection

    def test_import_remaps_and_preserves_password_and_read_only(self):
        connection = self.source()
        with patch.dict(os.environ, {'RAILS_DATABASE_URL': 'postgresql://unused'}), patch('psycopg.connect') as connect:
            connect.return_value.__enter__.return_value = connection
            call_command('import_rails', stdout=io.StringIO())
        connection.execute.assert_any_call('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ READ ONLY')
        user = User.objects.get(email='old@example.com')
        self.assertTrue(user.check_password(PASSWORD))
        self.assertEqual(Transaction.objects.get().category.user_id, user.pk)
        self.assertEqual(Transaction.objects.get().amount_cents, 123)
        with self.assertRaises(CommandError):
            call_command('import_rails', stdout=io.StringIO())

    def test_invalid_import_rolls_back(self):
        with patch.dict(os.environ, {'RAILS_DATABASE_URL': 'postgresql://unused'}), patch('psycopg.connect') as connect:
            connect.return_value.__enter__.return_value = self.source(invalid=True)
            with self.assertRaises(ValidationError):
                call_command('import_rails', stdout=io.StringIO())
        self.assertEqual(User.objects.count(), 0)
        self.assertEqual(Category.objects.count(), 0)
