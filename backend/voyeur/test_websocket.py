from websocket import WebSocketApp, enableTrace
import json

enableTrace(True)

up_data = []

def on_open(ws):
    print("Connected to", ws.url)

def on_message(ws, message):
    try:
        data = json.loads(message)
        up_data.append(data)
        if len(up_data) == 10:
            print(up_data)
            ws.close()
    except json.JSONDecodeError as e:
        print(f"Error decoding message: {e}")

def on_close(ws, status_code, message):
    print(f"Connection closed. Status: {status_code}, Message: {message}")

def on_error(ws, error):
    print("Error:", error)

def connect_metrics():
    ws_url = "ws://0.0.0.0:8080/tymb/metrics"
    ws = WebSocketApp(
        ws_url,
        on_open=on_open,
        on_message=on_message,
        on_close=on_close,
        on_error=on_error,
        header={
            "Origin": "http://0.0.0.0:8080",
        }
    )
    ws.run_forever()

if __name__ == "__main__":
    connect_metrics()