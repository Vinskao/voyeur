import os
from pathlib import Path
import logging

# Configure logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = os.getenv('DJANGO_SECRET_KEY', 'django-insecure-default-key-for-development')
logger.debug(f"SECRET_KEY is set: {bool(SECRET_KEY)}")

# Get the host from environment or use default
HOST = os.getenv('DJANGO_HOST', '127.0.0.1:8000')
DJANGO_ENV = os.getenv('DJANGO_ENV', '')
IS_PRODUCTION = DJANGO_ENV.lower() == 'production'

logger.debug(f"DJANGO_ENV = {DJANGO_ENV}")
logger.debug(f"Environment: {'Production' if IS_PRODUCTION else 'Development'}")

# Base URL for API
BASE_URL = f"https://{HOST}" if IS_PRODUCTION else f"http://{HOST}"
logger.debug(f"Base URL: {BASE_URL}")

# Debug settings
DEBUG = not IS_PRODUCTION
ALLOWED_HOSTS = ['*']  # 暫時允許所有主機，用於調試
logger.debug(f"ALLOWED_HOSTS = {ALLOWED_HOSTS}")

# MongoDB settings
MONGODB_URI = os.getenv('MONGODB_URI')
if not MONGODB_URI or MONGODB_URI.startswith('${'):
    logger.error("MongoDB URI is not properly set!")
    raise ValueError("MongoDB URI must be set in environment variables")

logger.debug(f"MongoDB URI: {MONGODB_URI}")
MONGODB_DB = os.getenv('MONGODB_DB', 'voyeur')
MONGODB_COLLECTION = os.getenv('MONGODB_COLLECTION', 'metrics')
MONGODB_USERNAME = os.getenv('MONGODB_USERNAME')
MONGODB_PASSWORD = os.getenv('MONGODB_PASSWORD')
MONGODB_AUTH_SOURCE = os.getenv('MONGODB_AUTH_SOURCE', 'admin')

# WebSocket settings
WEBSOCKET_HOST = os.getenv('WEBSOCKET_HOST', 'localhost')
WEBSOCKET_PORT = int(os.getenv('WEBSOCKET_PORT', '8080'))
WEBSOCKET_PATH = os.getenv('WEBSOCKET_PATH', '/tymb/metrics')

# Application definition
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'visit',
    'rest_framework',
    'drf_yasg',
    'corsheaders',
    'metrics',
    'whitenoise.runserver_nostatic',  # Add WhiteNoise
]

MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',  # 必須放在最前面
    'whitenoise.middleware.WhiteNoiseMiddleware',  # Add WhiteNoise middleware
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

# CORS settings
CORS_ALLOW_ALL_ORIGINS = True
CORS_ALLOW_CREDENTIALS = True
CORS_ALLOWED_ORIGINS = [
    "https://peoplesystem.tatdvsonorth.com",
    "http://localhost:8000",
    "http://127.0.0.1:8000"
]
CORS_ALLOW_METHODS = [
    'DELETE',
    'GET',
    'OPTIONS',
    'PATCH',
    'POST',
    'PUT',
]
CORS_ALLOW_HEADERS = [
    'accept',
    'accept-encoding',
    'authorization',
    'content-type',
    'dnt',
    'origin',
    'user-agent',
    'x-csrftoken',
    'x-requested-with',
]

# CSRF settings
CSRF_TRUSTED_ORIGINS = [
    "https://peoplesystem.tatdvsonorth.com",
    "http://localhost:8000",
    "http://127.0.0.1:8000"
]
CSRF_COOKIE_SECURE = IS_PRODUCTION
CSRF_COOKIE_HTTPONLY = True
CSRF_USE_SESSIONS = True

# REST Framework settings
REST_FRAMEWORK = {
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.AllowAny',
    ],
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework.authentication.SessionAuthentication',
        'rest_framework.authentication.BasicAuthentication',
    ],
    'DEFAULT_PAGINATION_CLASS': 'rest_framework.pagination.PageNumberPagination',
    'PAGE_SIZE': 10
}

# Swagger settings
SWAGGER_SETTINGS = {
    'USE_SESSION_AUTH': False,
    'SECURITY_DEFINITIONS': {
        'Bearer': {
            'type': 'apiKey',
            'name': 'Authorization',
            'in': 'header'
        }
    },
    'VALIDATOR_URL': None,
    'OPERATIONS_SORTER': None,
    'TAGS_SORTER': None,
    'DOC_EXPANSION': 'none',
    'DEFAULT_MODEL_RENDERING': 'model',
    'DEFAULT_INFO': None,
    'DEFAULT_API_URL': f"{BASE_URL}/voyeur/",
}

ROOT_URLCONF = 'voyeur.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'voyeur.wsgi.application'

# Database
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }
}

# Password validation
AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',
    },
]

# Internationalization
LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'UTC'
USE_I18N = True
USE_TZ = True

# Static files (CSS, JavaScript, Images)
STATIC_URL = '/voyeur/static/' if IS_PRODUCTION else '/static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'

# Configure static files
STATICFILES_STORAGE = 'django.contrib.staticfiles.storage.ManifestStaticFilesStorage'
STATICFILES_FINDERS = [
    'django.contrib.staticfiles.finders.FileSystemFinder',
    'django.contrib.staticfiles.finders.AppDirectoriesFinder',
]

# Add security headers
SECURE_CONTENT_TYPE_NOSNIFF = True
SECURE_BROWSER_XSS_FILTER = True
X_FRAME_OPTIONS = 'DENY'

# Default primary key field type
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# ... rest of your settings ... 