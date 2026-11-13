from django.contrib.auth.models import AbstractUser
from django.core.validators import MinValueValidator, MaxValueValidator, RegexValidator
from django.db import models


class User(AbstractUser):
    username = models.CharField(max_length=254, unique=True)
    email = models.EmailField(unique=True)
    name = models.CharField('nome', max_length=100, blank=True)
    failed_attempts = models.PositiveIntegerField(default=0)
    locked_until = models.DateTimeField(null=True, blank=True)
    EMAIL_FIELD = 'email'


class OwnedModel(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        abstract = True


class Category(OwnedModel):
    name = models.CharField('nome', max_length=60)
    color = models.CharField('cor', max_length=7, blank=True, validators=[RegexValidator(r'^#[0-9a-fA-F]{6}$')])
    icon = models.CharField('ícone', max_length=32, blank=True)

    def __str__(self):
        return self.name


class CreditCard(OwnedModel):
    name = models.CharField('nome', max_length=60)
    limit_cents = models.BigIntegerField('limite em centavos', validators=[MinValueValidator(0), MaxValueValidator(2147483647)])
    closing_day = models.PositiveSmallIntegerField('dia de fechamento', validators=[MinValueValidator(1), MaxValueValidator(31)])
    due_day = models.PositiveSmallIntegerField('dia de vencimento', validators=[MinValueValidator(1), MaxValueValidator(31)])

    def __str__(self):
        return self.name


class Transaction(OwnedModel):
    description = models.CharField('descrição', max_length=120)
    amount_cents = models.BigIntegerField('valor em centavos', validators=[MinValueValidator(1), MaxValueValidator(2147483647)])
    kind = models.CharField('tipo', max_length=7, choices=[('income', 'Receita'), ('expense', 'Despesa')])
    occurred_on = models.DateField('data')
    installments_count = models.PositiveSmallIntegerField('parcelas', default=1, validators=[MinValueValidator(1), MaxValueValidator(36)])
    category = models.ForeignKey(Category, verbose_name='categoria', on_delete=models.SET_NULL, blank=True, null=True)
    credit_card = models.ForeignKey(CreditCard, verbose_name='cartão', on_delete=models.SET_NULL, blank=True, null=True)

    def clean(self):
        from django.core.exceptions import ValidationError
        for field in ('category', 'credit_card'):
            related = getattr(self, field, None)
            if related and related.user_id != self.user_id:
                raise ValidationError({field: 'Este registro não pertence à sua conta.'})


class RateLimit(models.Model):
    key = models.CharField(max_length=64, primary_key=True)
    count = models.PositiveIntegerField(default=0)
    expires_at = models.DateTimeField(db_index=True)
