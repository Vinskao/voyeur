# 使用官方 Python 映像作為基礎映像
FROM python:3.12-slim

# 設定工作目錄
WORKDIR /app

# 複製 pyproject.toml 和 poetry.lock
COPY pyproject.toml poetry.lock ./

# 安裝 Poetry
RUN pip install --no-cache-dir poetry

# 使用 Poetry 安裝 Python 依賴項
RUN poetry config virtualenvs.create false \
    && poetry install --no-root --only main

# 複製其餘的專案文件
COPY . .

# 根據環境變數選擇正確的 .env 文件
ARG DJANGO_ENV=production
RUN if [ "$DJANGO_ENV" = "production" ]; then \
        cp .env.production .env; \
    else \
        cp .env .env; \
    fi

# 收集靜態文件
RUN poetry run python manage.py collectstatic --noinput

# 設定環境變數
ENV DJANGO_SETTINGS_MODULE=voyeur.settings
ENV DJANGO_ENV=${DJANGO_ENV}

# 暴露 Django 預設的埠
EXPOSE 8000

# 啟動命令
CMD ["sh", "-c", "poetry run python manage.py runserver 0.0.0.0:8000"]