#!/usr/bin/env python
"""Django's command-line utility for administrative tasks."""
import os
import sys
import subprocess


def main():
    """Run administrative tasks."""
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
    
    # Import and run the scheduler
    try:
        import voyeur.scheduler
        voyeur.scheduler.run()  # Call the run function
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

    # Start the scheduler in a separate process
    subprocess.Popen(["python", "scheduler.py"])

    execute_from_command_line(sys.argv)


if __name__ == '__main__':
    main()