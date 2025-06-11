# Voyeur

這是一個用於收集和提供指標數據的後端服務。

# Voyeur API

## Technical Architecture

```mermaid
graph TB
    subgraph Client
        C[Client Applications]
    end

    subgraph Ingress
        I[NGINX Ingress]
    end

    subgraph Kubernetes
        subgraph Pod
            D[Django Application]
            subgraph Applications
                V[Visit App]
                M[Metrics App]
                VO[Voyeur App]
            end
        end
        
        subgraph Database
            MONGO[(MongoDB)]
        end
    end

    C -->|HTTPS| I
    I -->|/voyeur| D
    D --> Applications
    Applications --> MONGO

    classDef k8s fill:#326ce5,stroke:#326ce5,color:white
    classDef app fill:#2ecc71,stroke:#27ae60,color:white
    classDef db fill:#e74c3c,stroke:#c0392b,color:white
    classDef ingress fill:#f1c40f,stroke:#f39c12,color:black

    class Kubernetes k8s
    class D,Applications app
    class MONGO db
    class I ingress
```

## API Endpoints

### Visit API
- `GET /visit/count` - Get visit count
- `POST /visit/increment` - Increment visit count

### Swagger Documentation
- `http://127.0.0.1:8000/voyeur/swagger.json`
- `https://peoplesystem.tatdvsonorth.com/voyeur/swagger.json`

```bash
curl http://127.0.0.1:8000/voyeur/swagger.json
curl http://127.0.0.1:8000/voyeur/count/
curl https://peoplesystem.tatdvsonorth.com/voyeur/swagger.json
curl https://peoplesystem.tatdvsonorth.com/voyeur/count/
```

## Development Setup

1. Install dependencies:
```bash
poetry install
```

2. Set up environment variables:
```bash
cp .env.example .env
# Edit .env with your configuration
```

3. Run migrations:
```bash
poetry run python manage.py migrate
```

4. Start development server:
```bash
poetry run python manage.py runserver
```


## WebSocket Connection

Test WebSocket connection using wscat:
```bash
wscat -c ws://localhost:8000/ws/metrics/
```

## Django User
```bash
poetry run python manage.py createsuperuser
```

DEBUG:voyeur.settings:ALLOWED_HOSTS: ['*']
Username (leave blank to use 'vinskao'): 
Email address: tianyikao@gmail.com