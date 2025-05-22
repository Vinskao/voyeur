import threading
import time
import logging
from .connect import connect_metrics

# 設置日誌系統
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def start_thread(name, target):
    """建立並啟動一個 daemon 線程"""
    thread = threading.Thread(target=target, name=name, daemon=True)
    thread.start()
    logger.info(f"Thread {name} started.")
    return thread

def main():
    """主函數，負責啟動 scheduler 並保持主程序長時間運行"""
    # 初始化線程字典
    threads = {
        "connect": start_thread("ConnectMetricsThread", connect_metrics),
    }
    
    try:
        # 持續監控線程狀態，每5秒檢查一次
        while True:
            time.sleep(5)
            # 對每個線程進行檢查，如果線程已停止則記錄錯誤訊息
            for name, thread in list(threads.items()):
                if not thread.is_alive():
                    logger.error(f"{name} thread has stopped.")
    except KeyboardInterrupt:
        logger.info("Scheduler stopped by user.")

def run():
    """對外接口，啟動 scheduler 系統"""
    main()

if __name__ == "__main__":
    main() 