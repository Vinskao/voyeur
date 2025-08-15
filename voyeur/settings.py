import os
from pathlib import Path
import logging
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Configure logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = os.getenv('VOYEUR_SECRET_KEY', 'django-insecure-development-key-change-in-production')
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
WEBSOCKET_TYMB = os.getenv('WEBSOCKET_TYMB', 'ws://localhost:8080/tymb/')

# Parse WebSocket URL to extract components
def parse_websocket_url(url):
    """Parse WebSocket URL to extract host, port, and path"""
    if url.startswith('ws://'):
        url = url[5:]  # Remove 'ws://'
    elif url.startswith('wss://'):
        url = url[6:]  # Remove 'wss://'
    
    # Split host:port and path
    if '/' in url:
        host_port, path = url.split('/', 1)
        path = '/' + path
    else:
        host_port = url
        path = '/'
    
    # Split host and port
    if ':' in host_port:
        host, port = host_port.split(':')
        port = int(port)
    else:
        host = host_port
        port = 80 if url.startswith('ws://') else 443
    
    return host, port, path

# Extract components from WEBSOCKET_TYMB
WEBSOCKET_HOST, WEBSOCKET_PORT, WEBSOCKET_PATH = parse_websocket_url(WEBSOCKET_TYMB)

# Full WebSocket URL with /metrics hardcoded
WEBSOCKET_URL = WEBSOCKET_TYMB + 'metrics'

# Application definition
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'rest_framework',
    'drf_yasg',
    'corsheaders',
    'visit',
    'metrics',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

# CORS settings
CORS_ALLOW_ALL_ORIGINS = True  # For development only
CORS_ALLOWED_ORIGINS = [
    "http://localhost:3000",
    "http://127.0.0.1:3000",
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
    'DEFAULT_RENDERER_CLASSES': [
        'rest_framework.renderers.JSONRenderer',
    ],
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
FORCE_SCRIPT_NAME = '/voyeur'
SWAGGER_SETTINGS = {
    'USE_SESSION_AUTH': False,
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

# Static files (CSS, JavaScript, Images)
STATIC_URL = '/static/'

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

# Add security headers
SECURE_CONTENT_TYPE_NOSNIFF = True
SECURE_BROWSER_XSS_FILTER = True
X_FRAME_OPTIONS = 'DENY'

# Default primary key field type
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'