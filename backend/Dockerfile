# 1. Imagen base de Python ligera
FROM python:3.11-slim

# 2. Variables de entorno para evitar archivos basura y ver logs
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# 3. Directorio de trabajo dentro del contenedor
WORKDIR /app

# 4. Instalamos dependencias del sistema para PostgreSQL y procesamiento de imágenes
# libpq-dev es para Postgres, libmagic1 para detectar tipos de archivos
RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    libmagic1 \
    && rm -rf /var/lib/apt/lists/*

# 5. Copiamos e instalamos los requerimientos de Python
# Lo hacemos antes de copiar el código para aprovechar la caché de Docker
COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt

# 6. Copiamos el resto del código del proyecto
COPY . /app/

# 7. Puerto por donde corre Django
EXPOSE 8000

# 8. Comando para arrancar (aunque el docker-compose lo sobrescriba, es buena práctica)
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]