#!/bin/bash
set -e

echo "🔧 Running Django migrations..."
python manage.py migrate

echo "👤 Creating/verifying test user..."
python manage.py shell << END
from django.contrib.auth.models import User

if not User.objects.filter(username='testuser').exists():
    User.objects.create_superuser('testuser', 'test@example.com', 'password123')
    print('✓ Test user created: testuser / password123')
else:
    print('✓ Test user already exists')
END

echo "🚀 Starting Django server..."
python manage.py runserver 0.0.0.0:8000
