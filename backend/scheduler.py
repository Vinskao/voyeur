import schedule
import time
import subprocess

def run_test_websocket():
    # Run the test_websocket.py script
    subprocess.run(["python", "voyeur/test_websocket.py"])

# Schedule the task to run every 5 seconds
schedule.every(5).seconds.do(run_test_websocket)

if __name__ == "__main__":
    print("Starting scheduler...")
    while True:
        schedule.run_pending()
        time.sleep(1) 