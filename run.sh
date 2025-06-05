#!/bin/bash

# Default to development if no environment specified
ENV=${1:-development}

if [ "$ENV" = "production" ]; then
    echo "Starting in PRODUCTION mode..."
    export DJANGO_ENV=production
else
    echo "Starting in DEVELOPMENT mode..."
    export DJANGO_ENV=development
fi

# Run Django server
python manage.py runserver 