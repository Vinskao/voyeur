# 使用官方 Python 映像作為基礎映像
FROM python:3.12-slim

# 設定工作目錄
WORKDIR /app

# 複製當前目錄內容到容器中的 /app
COPY . /app

# 安裝 Poetry
RUN pip install --no-cache-dir poetry

# 使用 Poetry 安裝 Python 依賴項
RUN poetry install

# 設定環境變數
ENV DJANGO_SETTINGS_MODULE=voyeur.settings

# 暴露 Django 預設的埠
EXPOSE 8000

# 啟動命令
CMD ["sh", "-c", "poetry run python manage.py runserver 0.0.0.0:8000"]