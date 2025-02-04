import os  # 用於操作系統層級的環境變數設定
import threading  # 用於啟動背景執行緒
from django.core.asgi import get_asgi_application  # 建立 Django ASGI 應用程式
from channels.routing import ProtocolTypeRouter, URLRouter  # 根據連線類型設定路由
from channels.auth import AuthMiddlewareStack  # 整合 Django Session 與身份驗證到 WebSocket
from channels.security.websocket import AllowedHostsOriginValidator  # 驗證 WebSocket 連線來源是否允許
from django.urls import path  # 配置 WebSocket 路由
from voyeur.consumers import AdminMetricsConsumer, PublicMetricsConsumer  # 已定義的 WebSocket 消費者類別

# 從 scheduler 模組引入 run 函數，這會啟動 connect_metrics 與 run_orm_metrics 任務
from voyeur.scheduler import run as run_scheduler

# 設定 Django 的預設設定模組為 core.settings
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')

# 初始化 Django 的 ASGI 應用，用來處理 HTTP 請求
django_asgi_app = get_asgi_application()

# 啟動 scheduler 任務的 daemon 線程，scheduler 內部會啟動兩個子線程：
# 一個用於 connect_metrics，另一個用於 run_orm_metrics (請確保 orm_metrics.py 中的 run_orm_metrics 定義已啟用)
threading.Thread(target=run_scheduler, name="SchedulerThread", daemon=True).start()

# 定義 ASGI 應用，根據不同連線類型（HTTP、WebSocket）分派請求
application = ProtocolTypeRouter({
    # 處理 HTTP 連線請求
    "http": django_asgi_app,
    
    # 處理 WebSocket 連線請求
    "websocket": AllowedHostsOriginValidator(  # 檢查連線來源是否在允許的清單內
         AuthMiddlewareStack(  # 將 Django session 與身份驗證整合到 WebSocket 連線中
            URLRouter([  # 根據 URL 路徑決定使用哪個 WebSocket 消費者處理請求
                path("metrics/admin/", AdminMetricsConsumer.as_asgi()),
                path("metrics/", PublicMetricsConsumer.as_asgi()),
            ])
         )
    ),
}) 