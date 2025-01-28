import logging
from stomp import Connection

# Configure logging
logging.basicConfig(level=logging.INFO)

class MetricsListener:
    def on_message(self, frame):
        print(f"Received message: {frame.body}")

def test_stomp():
    conn = Connection([("localhost", 8080)])
    conn.set_listener('', MetricsListener())
    conn.connect(wait=True, headers={
        "Authorization": "Bearer your_token",  # If authentication is needed
        "Custom-Header": "custom_value"        # Replace with any required headers
    })
    
    # Subscribe to the /topic/metrics
    conn.subscribe(destination="/topic/metrics", id="1", ack="auto")
    
    print("Subscribed to /topic/metrics")
    
    try:            
        while True:
            pass
    except KeyboardInterrupt:
        conn.disconnect()

if __name__ == "__main__":
    test_stomp()
