#!/usr/bin/env python
"""Django's command-line utility for administrative tasks."""
import os
import sys
import threading

def main():
    """Run administrative tasks."""
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
    
    # 以 daemon 線程的方式啟動 scheduler，避免阻塞
    try:
        import voyeur.scheduler
        threading.Thread(target=voyeur.scheduler.run, name="SchedulerThread", daemon=True).start()
    except ImportError as exc:
        raise ImportError(
            "Couldn't import voyeur.scheduler. Are you sure it's installed and "
            "available on your PYTHONPATH environment variable?"
        ) from exc
    
    try:
        from django.core.management import execute_from_command_line
    except ImportError as exc:
        raise ImportError(
            "Couldn't import Django. Are you sure it's installed and "
            "available on your PYTHONPATH environment variable? Did you "
            "forget to activate a virtual environment?"
        ) from exc
    
    execute_from_command_line(sys.argv)

if __name__ == '__main__':
    main()