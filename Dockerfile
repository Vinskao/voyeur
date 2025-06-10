# 使用官方 Python 映像作為基礎映像
FROM python:3.12-slim

# 設定工作目錄
WORKDIR /app

# 定義 build arguments
ARG MONGODB_URI
ARG MONGODB_USERNAME
ARG MONGODB_PASSWORD
ARG MONGODB_AUTH_SOURCE
ARG DJANGO_SECRET_KEY
ARG DJANGO_HOST
ARG DJANGO_ENV
ARG DJANGO_ALLOWED_HOSTS

# 複製 pyproject.toml 和 poetry.lock
COPY pyproject.toml poetry.lock ./

# 安裝 Poetry
RUN pip install --no-cache-dir poetry

# 使用 Poetry 安裝 Python 依賴項
RUN poetry config virtualenvs.create false \
    && poetry install --no-root --only main

# 複製其餘的專案文件
COPY . .

# 設定環境變數
ENV MONGODB_URI=${MONGODB_URI}
ENV MONGODB_USERNAME=${MONGODB_USERNAME}
ENV MONGODB_PASSWORD=${MONGODB_PASSWORD}
ENV MONGODB_AUTH_SOURCE=${MONGODB_AUTH_SOURCE}
ENV DJANGO_SECRET_KEY=${DJANGO_SECRET_KEY}
ENV DJANGO_HOST=${DJANGO_HOST}
ENV DJANGO_ENV=${DJANGO_ENV}
ENV DJANGO_ALLOWED_HOSTS=${DJANGO_ALLOWED_HOSTS}
ENV DJANGO_SETTINGS_MODULE=voyeur.settings

# 收集靜態文件
RUN poetry run python manage.py collectstatic --noinput --clear

# 設定權限
RUN chmod -R 755 /app/staticfiles

# 暴露 Django 預設的埠
EXPOSE 8000

# 啟動命令
CMD ["sh", "-c", "poetry run python manage.py runserver 0.0.0.0:8000"]