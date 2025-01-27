import asyncio
import websockets

async def connect_to_metrics():
    uri = "ws://localhost:8080/tymb/metrics"
    
    try:
        async with websockets.connect(uri) as websocket:
            print("Connected to the WebSocket server")
            
            while True:
                data = await websocket.recv()
                print(f"Received data: {data}")

    except Exception as e:
        print(f"An error occurred: {str(e)}")  # 添加更詳細的錯誤信息

if __name__ == "__main__":
    asyncio.run(connect_to_metrics()) 