from django import template
register = template.Library()

@register.filter
def money(value):
    cents = int(value or 0)
    sign = '-' if cents < 0 else ''
    whole, fraction = divmod(abs(cents), 100)
    return f"{sign}R$ {whole:,},{fraction:02d}".replace(',', '.', f"{whole:,}".count(','))
