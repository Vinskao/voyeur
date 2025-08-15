#!/usr/bin/env python3
"""
MongoDB 連線測試腳本
"""

import os
from pymongo import MongoClient
from dotenv import load_dotenv

def test_mongodb_connection():
    """測試 MongoDB 連線"""
    print("=== MongoDB 連線測試 ===")
    
    # 載入環境變數
    load_dotenv()
    
    # 取得連線字串
    connection_string = os.getenv('MONGODB_URI')
    print(f"連線字串: {connection_string}")
    
    # 嘗試不同的連線方式
    connection_methods = [
        {
            "name": "使用完整 URI（含帳密）",
            "client": lambda: MongoClient(connection_string)
        },
        {
            "name": "使用 URI + 額外認證參數",
            "client": lambda: MongoClient(
                connection_string,
                username="tianyikao",
                password="wawi247525",
                authSource="admin"
            )
        },
        {
            "name": "使用 URI + 不同認證資料庫",
            "client": lambda: MongoClient(
                connection_string,
                username="tianyikao",
                password="wawi247525",
                authSource="voyeur"
            )
        }
    ]
    
    for method in connection_methods:
        print(f"\n--- 測試方法: {method['name']} ---")
        try:
            # 建立連線
            print("正在建立連線...")
            client = method['client']()
            
            # 測試連線
            print("正在測試連線...")
            client.admin.command('ping')
            print("✅ MongoDB 連線成功!")
            
            # 列出所有資料庫
            print("\n=== 可用的資料庫 ===")
            databases = client.list_database_names()
            for db in databases:
                print(f"- {db}")
            
            # 測試 voyeur 資料庫
            print("\n=== 測試 voyeur 資料庫 ===")
            db = client['voyeur']
            collections = db.list_collection_names()
            print(f"Collections in voyeur: {collections}")
            
            # 測試 tyf_visits collection
            print("\n=== 測試 tyf_visits collection ===")
            collection = db['tyf_visits']
            
            # 檢查是否有計數器文件
            counter = collection.find_one({'_id': 'visit_counter'})
            if counter:
                print(f"✅ 找到計數器: count={counter['count']}, last_updated={counter['last_updated']}")
            else:
                print("ℹ️  計數器文件不存在，會在首次訪問時自動建立")
            
            # 測試寫入權限
            print("\n=== 測試寫入權限 ===")
            test_doc = {'_id': 'test_connection', 'timestamp': '2024-01-01T00:00:00Z'}
            collection.insert_one(test_doc)
            print("✅ 寫入測試成功")
            
            # 清理測試文件
            collection.delete_one({'_id': 'test_connection'})
            print("✅ 清理測試文件成功")
            
            client.close()
            print("\n🎉 所有測試通過!")
            return True
            
        except Exception as e:
            print(f"❌ MongoDB 連線失敗: {e}")
            print(f"錯誤類型: {type(e).__name__}")
            continue
    
    print("\n❌ 所有連線方法都失敗了")
    return False

if __name__ == "__main__":
    test_mongodb_connection()
