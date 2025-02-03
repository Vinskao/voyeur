from django.apps import AppConfig
import threading
from voyeur.scheduler import run

class CoreConfig(AppConfig):
    name = 'core'

    def ready(self):
        # 為避免在 Django 的自動 reload 機制中重複啟動，做必要判斷
        import os
        if os.environ.get('RUN_MAIN', None) != 'true':
            return

        t = threading.Thread(target=run, name="SchedulerThread", daemon=True)
        t.start() 