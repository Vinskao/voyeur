import threading
import time
from .connect_metrics import connect_metrics

def run_connect_metrics():
    while True:
        connect_metrics()  # Call the correct function
        time.sleep(30)  # Retry every x seconds

def start_scheduler():
    thread = threading.Thread(target=run_connect_metrics)
    thread.daemon = True  # Ensure the thread exits when the main program does
    thread.start() 

def main():
    # Start the scheduler
    start_scheduler()
    
    # Keep the main program running
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print("Scheduler stopped.")

def run():
    """Run the scheduler."""
    main()

if __name__ == "__main__":
    main() 