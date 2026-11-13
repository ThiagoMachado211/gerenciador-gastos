import os
from pathlib import Path
from urllib.parse import urlparse, parse_qs, unquote

BASE_DIR = Path(__file__).resolve().parent.parent
DEBUG = os.environ.get('DEBUG', 'true').lower() == 'true'
SECRET_KEY = os.environ.get('SECRET_KEY', 'local-development-only-change-before-deploy')
if not DEBUG and SECRET_KEY == 'local-development-only-change-before-deploy':
    raise RuntimeError('Defina SECRET_KEY em produÃ§Ã£o.')
ALLOWED_HOSTS = os.environ.get('ALLOWED_HOSTS', 'localhost,127.0.0.1,[::1]').split(',')
INSTALLED_APPS = ['django.contrib.auth', 'django.contrib.contenttypes', 'django.contrib.sessions',
                  'django.contrib.messages', 'django.contrib.staticfiles', 'backend.finance']
MIDDLEWARE = ['django.middleware.security.SecurityMiddleware', 'whitenoise.middleware.WhiteNoiseMiddleware',
              'django.contrib.sessions.middleware.SessionMiddleware', 'django.middleware.common.CommonMiddleware',
              'django.middleware.csrf.CsrfViewMiddleware', 'django.contrib.auth.middleware.AuthenticationMiddleware',
              'django.contrib.messages.middleware.MessageMiddleware', 'django.middleware.clickjacking.XFrameOptionsMiddleware',
              'backend.finance.middleware.SecurityHeaders']
ROOT_URLCONF = 'backend.urls'
WSGI_APPLICATION = 'backend.wsgi.application'
TEMPLATES = [{'BACKEND': 'django.template.backends.django.DjangoTemplates', 'DIRS': [BASE_DIR / 'frontend/templates'],
              'APP_DIRS': True, 'OPTIONS': {'context_processors': ['django.template.context_processors.request',
              'django.contrib.auth.context_processors.auth', 'django.contrib.messages.context_processors.messages']}}]
DATABASES = {'default': {'ENGINE': 'django.db.backends.sqlite3', 'NAME': BASE_DIR / 'storage/fluxo.sqlite3', 'OPTIONS': {'timeout': 20}}}
if os.environ.get('DATABASE_URL'):
    url = urlparse(os.environ['DATABASE_URL'])
    if url.scheme not in ('postgres', 'postgresql'):
        raise RuntimeError('DATABASE_URL deve usar PostgreSQL.')
    DATABASES['default'] = {'ENGINE': 'django.db.backends.postgresql', 'NAME': unquote(url.path[1:]),
        'USER': unquote(url.username or ''), 'PASSWORD': unquote(url.password or ''), 'HOST': url.hostname, 'PORT': url.port or 5432,
        'OPTIONS': {key: value[-1] for key, value in parse_qs(url.query).items()}}
AUTH_USER_MODEL = 'finance.User'
AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator', 'OPTIONS': {'min_length': 12}},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
    {'NAME': 'backend.finance.validators.AdminPasswordValidator'},
]
LANGUAGE_CODE = 'pt-br'
TIME_ZONE = 'America/Sao_Paulo'
USE_TZ = True
STATIC_URL = '/static/'
STATICFILES_DIRS = [BASE_DIR / 'frontend/static']
STATIC_ROOT = BASE_DIR / 'staticfiles'
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'
LOGIN_URL = '/users/sign_in'
LOGIN_REDIRECT_URL = '/users/dashboard'
LOGOUT_REDIRECT_URL = '/'
SESSION_COOKIE_HTTPONLY = True
SESSION_COOKIE_SAMESITE = 'Lax'
SESSION_COOKIE_SECURE = not DEBUG
CSRF_COOKIE_SECURE = not DEBUG
SECURE_SSL_REDIRECT = not DEBUG
SECURE_HSTS_SECONDS = 31536000 if not DEBUG else 0
SECURE_HSTS_INCLUDE_SUBDOMAINS = not DEBUG
SECURE_HSTS_PRELOAD = not DEBUG
SECURE_CONTENT_TYPE_NOSNIFF = True
SECURE_REFERRER_POLICY = 'same-origin'
CSRF_TRUSTED_ORIGINS = [x for x in os.environ.get('CSRF_TRUSTED_ORIGINS', '').split(',') if x]
EMAIL_BACKEND = 'django.core.mail.backends.console.EmailBackend' if DEBUG else 'django.core.mail.backends.smtp.EmailBackend'
EMAIL_HOST = os.environ.get('SMTP_HOST', '')
EMAIL_PORT = int(os.environ.get('SMTP_PORT', '587'))
EMAIL_HOST_USER = os.environ.get('SMTP_USERNAME', '')
EMAIL_HOST_PASSWORD = os.environ.get('SMTP_PASSWORD', '')
EMAIL_USE_TLS = True
DEFAULT_FROM_EMAIL = os.environ.get('MAIL_FROM', 'Fluxo <noreply@localhost>')
PASSWORD_RESET_TIMEOUT = 3600

PASSWORD_HASHERS = ['django.contrib.auth.hashers.PBKDF2PasswordHasher', 'backend.finance.hashers.DeviseBCryptPasswordHasher']
