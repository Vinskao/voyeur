import asyncio
import logging
from stomp import Connection


# Configure logging
logging.basicConfig(level=logging.INFO)

class MetricsListener:
    def on_message(self, frame):
        print(f"Received message: {frame.body}")
def connect_to_stomp():
    conn = Connection([("0.0.0.0", 8080)])
    conn.set_listener('', MetricsListener())
    conn.connect(wait=True)
    
    conn.subscribe(destination="/tymb/metrics", id="1", ack="auto")
    
    print("Subscribed to /tymb/metrics")
    
    try:            
        while True:
            pass
    except KeyboardInterrupt:
        conn.disconnect()

if __name__ == "__main__":
    connect_to_stomp()