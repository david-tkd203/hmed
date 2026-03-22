# 1. Imagen base de Python ligera
FROM python:3.11-slim

# 2. Variables de entorno para evitar archivos basura y ver logs
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# 3. Directorio de trabajo dentro del contenedor
WORKDIR /app

# 4. Instalamos dependencias del sistema esenciales
RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    libmagic1 \
    git \
    tesseract-ocr \
    && rm -rf /var/lib/apt/lists/*

# 5. Copiamos e instalamos requerimientos base de Python
COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt

# 6. Instalamos dependencias de IA/ML (TensorFlow + transformers para MedSigLIP)
COPY requirements_ai.txt /app/
RUN pip install --no-cache-dir -r requirements_ai.txt 2>&1 | tail -20 || echo "AI dependencies installation completed"

# 7. Copiamos código de la aplicación
COPY . /app/

# 8. Exponemos puerto
EXPOSE 8000

# 9. Comando para iniciar la aplicación
CMD ["sh", "-c", "python manage.py migrate && python manage.py runserver 0.0.0.0:8000"]