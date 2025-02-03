import multiprocessing
import logging
from wsgiref.simple_server import make_server

def run_django():
    """
    啟動 Django HTTP 服務，使用 WSGI 介面 (wsgiref.simple_server)
    """
    # 從 Django WSGI 模組載入應用程式
    from core.wsgi import application
    logging.info("Starting Django WSGI server on port 8000")
    server = make_server("0.0.0.0", 8000, application)
    server.serve_forever()

def run_websocket():
    """
    啟動 WebSocket 服務，連線並處理相關訊息
    """
    # 從 voyeur/connect_metrics 載入 connect_metrics
    from voyeur.connect_metrics import connect_metrics
    logging.info("Starting WebSocket service")
    connect_metrics()

if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    
    # 建立兩個不同的 process 分別啟動 Django 與 WebSocket
    django_process = multiprocessing.Process(target=run_django, name="DjangoHTTPServer")
    websocket_process = multiprocessing.Process(target=run_websocket, name="WebSocketService")

    # 啟動 services
    django_process.start()
    websocket_process.start()

    # 等待兩個 process 執行結束（通常是無限迴圈不會終止）
    django_process.join()
    websocket_process.join() 