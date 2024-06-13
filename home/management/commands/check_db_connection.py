from django.core.management.base import BaseCommand
from django.db import connection

class Command(BaseCommand):
    help = 'Check database connection'

    def handle(self, *args, **kwargs):
        try:
            # Execute a simple SQL query to check the connection
            with connection.cursor() as cursor:
                cursor.execute("SELECT 1")
                row = cursor.fetchone()
            if row:
                self.stdout.write(self.style.SUCCESS('Database connection is successful.'))
            else:
                self.stdout.write(self.style.ERROR('Database connection failed.'))
        except Exception as e:
            self.stdout.write(self.style.ERROR(f'Database connection failed: {e}'))
