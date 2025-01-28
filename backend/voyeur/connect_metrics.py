import asyncio
import logging
from stomp import Connection, ConnectionListener


# Configure logging
logging.basicConfig(level=logging.INFO)

class MetricsListener(ConnectionListener):
    def on_open(self, frame):
        print("Connected to STOMP broker")

    def on_message(self, frame):
        print(f"Received message: {frame.body}")
            
def connect_to_stomp():
    conn = Connection([("localhost", 8080)])
    listener = MetricsListener()
    conn.set_listener('', listener )
    conn.connect(wait=True)
    
    conn.subscribe(destination="/topic/metrics", id="1", ack="auto")
    print("Subscribed to /topic/metrics")
    
    try:            
        while True:
            pass
    except KeyboardInterrupt:
        conn.disconnect()

if __name__ == "__main__":
    connect_to_stomp()