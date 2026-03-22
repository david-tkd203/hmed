#!/bin/bash
set -e

echo "🔧 Running Django migrations..."
python manage.py migrate

echo "👤 Creating/verifying test user..."
TEST_USERNAME=${TEST_USERNAME:-testuser}
TEST_PASSWORD=${TEST_PASSWORD:-changeme}
TEST_EMAIL=${TEST_EMAIL:-test@example.local}

python manage.py shell << END
from django.contrib.auth.models import User

if not User.objects.filter(username='$TEST_USERNAME').exists():
    User.objects.create_superuser('$TEST_USERNAME', '$TEST_EMAIL', '$TEST_PASSWORD')
    print(f'✓ Test user created: $TEST_USERNAME')
else:
    print(f'✓ Test user already exists: $TEST_USERNAME')
END

echo "🚀 Starting Django server..."
python manage.py runserver 0.0.0.0:8000
