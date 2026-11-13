import os
from datetime import UTC
from django.core.management.base import BaseCommand, CommandError
from django.db import transaction
from backend.finance.models import User, Category, CreditCard, Transaction

class Command(BaseCommand):
    help = 'Importa o PostgreSQL Rails em modo somente leitura. Exige destino vazio.'

    @transaction.atomic
    def handle(self, *args, **options):
        import psycopg
        from psycopg.rows import dict_row
        if User.objects.exists():
            raise CommandError('O destino deve estar vazio. Use um banco novo para importar.')
        dsn = os.environ.get('RAILS_DATABASE_URL')
        if not dsn:
            raise CommandError('Defina RAILS_DATABASE_URL com a conexão de origem.')
        with psycopg.connect(dsn, row_factory=dict_row) as source:
            source.execute('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ READ ONLY')
            rows = {table: source.execute(f'SELECT * FROM {table}').fetchall()
                    for table in ('users', 'categories', 'credit_cards', 'transactions')}
        # Rails stores timestamps without an offset, in UTC.
        for records in rows.values():
            for row in records:
                for key in ('created_at', 'updated_at', 'locked_at'):
                    value = row.get(key)
                    if value is not None and value.tzinfo is None:
                        row[key] = value.replace(tzinfo=UTC)
        users, categories, cards = {}, {}, {}
        for row in rows['users']:
            user = User(username=row['email'].lower(), email=row['email'].lower(), name=row.get('name') or '',
                is_staff=row.get('admin', False), is_superuser=row.get('admin', False),
                date_joined=row['created_at'], failed_attempts=row.get('failed_attempts', 0))
            # Django's legacy BCryptPasswordHasher accepts bcrypt$ + the Devise hash.
            encrypted = row.get('encrypted_password', '')
            if encrypted.startswith(('$2a$', '$2b$', '$2y$')):
                user.password = 'bcrypt$' + encrypted
            else:
                user.set_unusable_password()
            if row.get('locked_at'):
                from datetime import timedelta
                user.locked_until = row['locked_at'] + timedelta(minutes=30)
            user.save()
            users[row['id']] = user
        for table, model, mapping, fields in [
            ('categories', Category, categories, ('name', 'color', 'icon')),
            ('credit_cards', CreditCard, cards, ('name', 'limit_cents', 'closing_day', 'due_day')),
        ]:
            for row in rows[table]:
                values = {key: row[key] if row[key] is not None else '' for key in fields}
                obj = model(user=users[row['user_id']], **values)
                obj.full_clean()
                obj.save()
                model.objects.filter(pk=obj.pk).update(created_at=row['created_at'], updated_at=row['updated_at'])
                mapping[row['id']] = obj
        for row in rows['transactions']:
            obj = Transaction(user=users[row['user_id']], category=categories.get(row['category_id']),
                credit_card=cards.get(row['credit_card_id']), **{key: row[key] for key in
                ('description', 'amount_cents', 'kind', 'occurred_on', 'installments_count')})
            obj.full_clean()
            obj.save()
            Transaction.objects.filter(pk=obj.pk).update(created_at=row['created_at'], updated_at=row['updated_at'])
        self.stdout.write(self.style.SUCCESS('Importação concluída. Origem preservada. Links de recuperação antigos foram invalidados.'))
