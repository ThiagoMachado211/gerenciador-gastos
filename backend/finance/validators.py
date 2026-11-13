import re
from django.core.exceptions import ValidationError


class AdminPasswordValidator:
    def validate(self, password, user=None):
        if user and user.is_staff and (len(password) < 32 or not all(re.search(pattern, password) for pattern in ('[a-z]', '[A-Z]', '[0-9]', '[^a-zA-Z0-9]'))):
            raise ValidationError(self.get_help_text())

    def get_help_text(self):
        return 'Administradores precisam de 32 caracteres com maiúsculas, minúsculas, números e símbolos.'
