import threading
import time
import logging
from .connect_metrics import connect_metrics

# 設置日誌系統，配置級別為 INFO 以便於追蹤系統運行時的訊息
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# 定義執行 connect_metrics 任務的函數，每30秒呼叫一次 connect_metrics() 
# ---------------------------------------------------------------------------
def run_connect_metrics():
    """獨立線程中執行 connect_metrics，該函數內部包含無限迴圈"""
    logger.info("Starting connect_metrics")
    connect_metrics()


def start_thread(name, target):
    """建立並啟動一個 daemon 線程"""
    thread = threading.Thread(target=target, name=name, daemon=True)
    thread.start()
    logger.info(f"Thread {name} started.")
    return thread


# ---------------------------------------------------------------------------
# 主函數，負責啟動 scheduler 並保持主程序長時間運行
# ---------------------------------------------------------------------------
def main():
    # 初始化線程字典，只包含 connect_metrics 任務
    threads = {
        "connect": start_thread("ConnectMetricsThread", run_connect_metrics),
    }
    
    try:
        # 持續監控線程狀態，每5秒檢查一次
        while True:
            time.sleep(5)
            # 對每個線程進行檢查，如果線程已停止則重啟
            for name, thread in list(threads.items()):
                if not thread.is_alive():
                    logger.error(f"{name} thread has stopped. Restarting it.")
                    if name == "connect":
                        threads[name] = start_thread("ConnectMetricsThread", run_connect_metrics)
    except KeyboardInterrupt:
        logger.info("Scheduler stopped by user.")


# ---------------------------------------------------------------------------
# 提供外部調用的接口函數
# ---------------------------------------------------------------------------
def run():
    """對外接口，啟動 scheduler 系統"""
    main()


# ---------------------------------------------------------------------------
# 當前模塊作為主程序運行時，啟動主函數
# ---------------------------------------------------------------------------
if __name__ == "__main__":
    main() 