import getpass
import os
from django.core.management.base import BaseCommand, CommandError
from django.core.validators import validate_email
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError
from backend.finance.models import User

class Command(BaseCommand):
    help = 'Cria um administrador sem promover ou alterar contas existentes.'

    def handle(self, *args, **options):
        email = (os.environ.get('ADMIN_EMAIL') or input('E-mail: ')).strip().lower()
        password = os.environ.get('ADMIN_PASSWORD') or getpass.getpass('Senha: ')
        user = User(username=email, email=email, name='Administrador', is_staff=True, is_superuser=True)
        try:
            validate_email(email)
            validate_password(password, user)
        except ValidationError as error:
            raise CommandError('; '.join(error.messages))
        if User.objects.filter(email__iexact=email).exists() or User.objects.filter(username=email).exists():
            raise CommandError('Conta já existente. Nenhuma alteração realizada.')
        user.set_password(password)
        user.save()
        self.stdout.write(self.style.SUCCESS('Administrador criado. Acesse /admin após entrar.'))
