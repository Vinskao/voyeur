import os
from dotenv import load_dotenv

load_dotenv()

def get_mongo_config():
    connection_string = os.getenv('MONGODB_URI', 'mongodb://localhost:27017')

    # Detect if credentials are already embedded in the URI (e.g., mongodb+srv://user:pass@host/...)
    def uri_has_credentials(uri: str) -> bool:
        try:
            scheme_split = uri.split('://', 1)
            if len(scheme_split) != 2:
                return False
            authority = scheme_split[1]
            # credentials segment exists if there is an '@' and a ':' before it
            if '@' in authority:
                creds_part = authority.split('@', 1)[0]
                return ':' in creds_part
            return False
        except Exception:
            return False

    return {
        'connection_string': connection_string,
        'username': os.getenv('MONGODB_USERNAME'),
        'password': os.getenv('MONGODB_PASSWORD'),
        'auth_source': os.getenv('MONGODB_AUTH_SOURCE', 'admin'),
        'use_uri_credentials_only': uri_has_credentials(connection_string),
    }