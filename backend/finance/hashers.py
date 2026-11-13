import bcrypt
from django.contrib.auth.hashers import BCryptPasswordHasher

class DeviseBCryptPasswordHasher(BCryptPasswordHasher):
    # Ruby bcrypt truncates at 72 bytes. Preserve that behavior for imported hashes.
    def verify(self, password, encoded):
        try:
            _, data = encoded.split('$', 1)
            return bcrypt.checkpw(password.encode('utf-8')[:72], data.encode('ascii'))
        except (ValueError, TypeError, UnicodeError):
            return False
