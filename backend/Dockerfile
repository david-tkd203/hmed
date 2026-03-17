# 1. Imagen base de Python ligera
FROM python:3.11-slim

# 2. Variables de entorno para evitar archivos basura y ver logs
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# 3. Directorio de trabajo dentro del contenedor
WORKDIR /app

# 4. Instalamos dependencias del sistema (PostgreSQL, IA/ML)
RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    libmagic1 \
    git \
    && rm -rf /var/lib/apt/lists/*

# 5. Copiamos e instalamos los requerimientos de Python (base)
COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt

# 6. Instalamos dependencias opcionales de IA/ML
COPY requirements_ai.txt /app/
RUN pip install --no-cache-dir -r requirements_ai.txt || echo "IA dependencies installation attempted (some may fail on CPU-only systems)"

# 6. Copiamos el resto del código del proyecto
COPY . /app/

# 7. Puerto por donde corre Django
EXPOSE 8000

# 8. Comando para arrancar
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]