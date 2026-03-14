# 🚀 Guía de Despliegue - HMED

> **Guía paso a paso para desplegar la plataforma HMED en AWS y VPS**

---

## 📑 Tabla de Contenidos

- [Resumen de Opciones](#resumen-de-opciones)
- [Opción 1: Despliegue en AWS (ECS + RDS)](#opción-1-despliegue-en-aws-ecs--rds)
- [Opción 2: Despliegue en AWS (EC2)](#opción-2-despliegue-en-aws-ec2)
- [Opción 3: Despliegue en VPS (Linux)](#opción-3-despliegue-en-vps-linux)
- [Configuración de Dominio](#configuración-de-dominio)
- [SSL/TLS con Let's Encrypt](#ssltls-con-lets-encrypt)
- [Monitoreo y Mantenimiento](#monitoreo-y-mantenimiento)
- [Rollback y Recovery](#rollback-y-recovery)

---

## 📊 Resumen de Opciones

| Opción | Plataforma | Dificultad | Costo | Escalabilidad | Usar si... |
|--------|-----------|-----------|-------|---------------|-----------|
| **ECS + RDS** | AWS | 🟡 Medio | 💰💰 | ⭐⭐⭐⭐⭐ | Necesitas autoescalado y confiabilidad |
| **EC2** | AWS | 🔴 Alto | 💰💰 | ⭐⭐⭐ | Prefieres control total y flexibilidad |
| **VPS Linux** | DigitalOcean, Linode | 🟢 Bajo | 💰 | ⭐⭐⭐ | Quieres simplicidad y bajo costo |

---

## 🏗️ Opción 1: Despliegue en AWS (ECS + RDS)

### Arquitectura
```
Internet Gateway
        ↓
    ALB (Application Load Balancer)
        ↓
   ECS Fargate Cluster
   (Contenedores Django + React)
        ↓
    RDS PostgreSQL
    (Base de datos managed)
```

### Ventajas
✅ Autoescalado automático  
✅ RDS manages backups y mantenimiento  
✅ Alta disponibilidad  
✅ Integración con AWS ecosystem  

### Pasos

#### 1️⃣ Preparar imágenes Docker

```bash
# Loguear en AWS ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  123456789.dkr.ecr.us-east-1.amazonaws.com

# Crear repositorio ECR para backend
aws ecr create-repository --repository-name hmed-backend --region us-east-1

# Construir imagen backend
docker build -t hmed-backend:1.0.0 ./backend

# Tagear imagen
docker tag hmed-backend:1.0.0 \
  123456789.dkr.ecr.us-east-1.amazonaws.com/hmed-backend:1.0.0

# Push a ECR
docker push 123456789.dkr.ecr.us-east-1.amazonaws.com/hmed-backend:1.0.0

# Repetir para frontend
aws ecr create-repository --repository-name hmed-frontend --region us-east-1
docker build -t hmed-frontend:1.0.0 ./frontend
docker tag hmed-frontend:1.0.0 \
  123456789.dkr.ecr.us-east-1.amazonaws.com/hmed-frontend:1.0.0
docker push 123456789.dkr.ecr.us-east-1.amazonaws.com/hmed-frontend:1.0.0
```

#### 2️⃣ Crear RDS PostgreSQL

```bash
aws rds create-db-instance \
  --db-instance-identifier hmed-db-prod \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --engine-version 15.0 \
  --master-username admin \
  --master-user-password "TuContraseñaSeguraAqui123!" \
  --allocated-storage 20 \
  --backup-retention-period 30 \
  --publicly-accessible false \
  --db-name hmed_db \
  --region us-east-1
```

**Espera 5-10 minutos a que se cree la BD...**

#### 3️⃣ Crear ECS Cluster

```bash
# Crear cluster
aws ecs create-cluster --cluster-name hmed-prod --region us-east-1

# Crear task definition para backend
```

**Crear archivo: `ecs-task-backend.json`**

```json
{
  "family": "hmed-backend",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "512",
  "memory": "1024",
  "containerDefinitions": [
    {
      "name": "hmed-backend",
      "image": "123456789.dkr.ecr.us-east-1.amazonaws.com/hmed-backend:1.0.0",
      "portMappings": [
        {
          "containerPort": 8000,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "DEBUG",
          "value": "False"
        },
        {
          "name": "ALLOWED_HOSTS",
          "value": "hmed.midominio.com,www.hmed.midominio.com"
        }
      ],
      "secrets": [
        {
          "name": "DATABASE_URL",
          "valueFrom": "arn:aws:secretsmanager:us-east-1:123456789:secret:hmed-db-url"
        },
        {
          "name": "SECRET_KEY",
          "valueFrom": "arn:aws:secretsmanager:us-east-1:123456789:secret:django-secret-key"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/hmed-backend",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
}
```

```bash
# Registrar task definition
aws ecs register-task-definition \
  --cli-input-json file://ecs-task-backend.json \
  --region us-east-1

# Crear servicio ECS
aws ecs create-service \
  --cluster hmed-prod \
  --service-name hmed-backend-service \
  --task-definition hmed-backend:1 \
  --desired-count 2 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-xxx],securityGroups=[sg-xxx],assignPublicIp=ENABLED}" \
  --load-balancers targetGroupArn=arn:aws:elasticloadbalancing:...,containerName=hmed-backend,containerPort=8000 \
  --region us-east-1
```

#### 4️⃣ Crear Load Balancer

```bash
# Crear ALB
aws elbv2 create-load-balancer \
  --name hmed-alb \
  --subnets subnet-xxx subnet-yyy \
  --security-groups sg-xxx \
  --region us-east-1

# Crear target group
aws elbv2 create-target-group \
  --name hmed-backend-tg \
  --protocol HTTP \
  --port 8000 \
  --vpc-id vpc-xxx \
  --target-type ip \
  --region us-east-1

# Crear listener
aws elbv2 create-listener \
  --load-balancer-arn arn:aws:elasticloadbalancing:... \
  --protocol HTTP \
  --port 80 \
  --default-actions Type=forward,TargetGroupArn=arn:aws:elasticloadbalancing:...
```

---

## 🖥️ Opción 2: Despliegue en AWS (EC2)

### Arquitectura
```
Internet → Route 53 (DNS)
    ↓
EC2 Instance (Ubuntu 22.04)
    ├── Docker
    ├── Docker Compose
    ├── Nginx (Reverse Proxy)
    ├── PostgreSQL (Container)
    └── Django + React (Containers)
```

### Ventajas
✅ Control total sobre la configuración  
✅ Menor precio que ECS  
✅ Flexibilidad total  

### Pasos

#### 1️⃣ Lanzar instancia EC2

```bash
# Opción manual en AWS Console:
# - Selecciona Ubuntu 22.04 LTS
# - t3.micro para desarrollo, t3.small para producción
# - Security Group: permite puerto 22, 80, 443
# - Storage: 30GB o más
```

#### 2️⃣ Conectar a la instancia

```bash
# Conectar vía SSH
ssh -i tu-clave.pem ubuntu@ec2-XX-XXX-XXX-XXX.compute-1.amazonaws.com

# Actualizar sistema
sudo apt update && sudo apt upgrade -y
```

#### 3️⃣ Instalar Docker y Docker Compose

```bash
# Instalar Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Agregar usuario al grupo docker
sudo usermod -aG docker ubuntu
newgrp docker

# Instalar Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
  -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verificar versiones
docker --version
docker-compose --version
```

#### 4️⃣ Clonar proyecto y configurar

```bash
# Clonar repositorio
cd /home/ubuntu
git clone https://github.com/tu-usuario/historico-clinico.git
cd historico-clinico

# Crear archivo .env para producción
cat > .env << 'EOF'
DEBUG=False
SECRET_KEY=tu-clave-super-secreta-random-aqui
ALLOWED_HOSTS=hmed.midominio.com,www.hmed.midominio.com
DATABASE_URL=postgres://admin:contraseña-segura@db:5432/hmed_db
POSTGRES_DB=hmed_db
POSTGRES_USER=admin
POSTGRES_PASSWORD=contraseña-segura
CORS_ALLOWED_ORIGINS=https://hmed.midominio.com,https://www.hmed.midominio.com
EOF

# Permisos
chmod 600 .env
```

#### 5️⃣ Modificar docker-compose para producción

**Editar `docker-compose.yml`:**

```yaml
version: '3.8'

services:
  db:
    image: postgres:15
    volumes:
      - postgres_data:/var/lib/postgresql/data/
    environment:
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    networks:
      - hmed_network
    restart: always
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER}"]
      interval: 10s
      timeout: 5s
      retries: 5

  web:
    build: ./backend
    command: gunicorn Hmed.wsgi:application --bind 0.0.0.0:8000 --workers 4
    volumes:
      - ./backend:/app
      - static_volume:/app/staticfiles
      - media_volume:/app/media
    environment:
      DEBUG: ${DEBUG}
      SECRET_KEY: ${SECRET_KEY}
      ALLOWED_HOSTS: ${ALLOWED_HOSTS}
      DATABASE_URL: ${DATABASE_URL}
      CORS_ALLOWED_ORIGINS: ${CORS_ALLOWED_ORIGINS}
    depends_on:
      db:
        condition: service_healthy
    networks:
      - hmed_network
    restart: always
    expose:
      - 8000

  nginx:
    image: nginx:alpine
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - static_volume:/app/staticfiles:ro
      - media_volume:/app/media:ro
    ports:
      - "80:80"
      - "443:443"
    depends_on:
      - web
    networks:
      - hmed_network
    restart: always

networks:
  hmed_network:
    driver: bridge

volumes:
  postgres_data:
  static_volume:
  media_volume:
```

#### 6️⃣ Crear configuración de Nginx

**Crear archivo: `nginx.conf`**

```nginx
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    client_max_body_size 20M;

    # Cache estático
    proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=my_cache:10m;

    upstream django {
        server web:8000;
    }

    server {
        listen 80;
        server_name hmed.midominio.com www.hmed.midominio.com;

        # Redirigir HTTP a HTTPS
        return 301 https://$server_name$request_uri;
    }

    server {
        listen 443 ssl http2;
        server_name hmed.midominio.com www.hmed.midominio.com;

        # Certificados SSL (se configura después con Let's Encrypt)
        ssl_certificate /etc/letsencrypt/live/hmed.midominio.com/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/hmed.midominio.com/privkey.pem;

        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers HIGH:!aNULL:!MD5;
        ssl_prefer_server_ciphers on;

        # Gzip compression
        gzip on;
        gzip_types text/plain text/css text/javascript application/json;
        gzip_min_length 1000;

        # Static files
        location /static/ {
            alias /app/staticfiles/;
            expires 1y;
            add_header Cache-Control "public, immutable";
        }

        location /media/ {
            alias /app/media/;
            expires 30d;
        }

        # Django API
        location /api/ {
            proxy_pass http://django;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # Admin panel
        location /admin/ {
            proxy_pass http://django;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # React frontend
        location / {
            proxy_pass http://django;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }
    }
}
```

#### 7️⃣ Levantar servicios

```bash
# Construir imágenes
docker-compose build

# Iniciar servicios
docker-compose up -d

# Ver logs
docker-compose logs -f

# Ejecutar migraciones
docker-compose exec web python manage.py migrate

# Crear superusuario
docker-compose exec web python manage.py createsuperuser

# Recolectar archivos estáticos
docker-compose exec web python manage.py collectstatic --noinput
```

---

## 🖥️ Opción 3: Despliegue en VPS (Linux)

### Proveedores recomendados
- **DigitalOcean** - $4-6/mes
- **Linode** - $5+/mes
- **Vultr** - $2.50+/mes
- **Hetzner** - €3+/mes

### Pasos

#### 1️⃣ Crear droplet/instancia

- OS: Ubuntu 22.04 LTS
- RAM: Mínimo 2GB
- CPU: Mínimo 1 vCPU
- Storage: Mínimo 30GB

#### 2️⃣ Configuración inicial

```bash
# SSH a la instancia
ssh root@TU_IP_VPS

# Actualizar sistema
apt update && apt upgrade -y

# Crear usuario no-root
adduser deploy
usermod -aG sudo deploy

# SSH setup para deploy user
sudo -u deploy mkdir -p /home/deploy/.ssh
sudo cp ~/.ssh/authorized_keys /home/deploy/.ssh/
sudo chown -R deploy:deploy /home/deploy/.ssh
sudo chmod 700 /home/deploy/.ssh
sudo chmod 600 /home/deploy/.ssh/authorized_keys

# Configurar SSH
sudo sed -i 's/#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sudo systemctl restart ssh

# Firewall
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

#### 3️⃣ Instalar dependencias

```bash
# Como deploy user
ssh deploy@TU_IP_VPS

# Instalar Docker y Docker Compose (igual que en EC2)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker deploy

# Instalar Git
sudo apt install git -y

# Instalar Certbot (para Let's Encrypt)
sudo apt install certbot python3-certbot-nginx -y
```

#### 4️⃣ Desplegar aplicación

```bash
# Clonar repo
cd /home/deploy
git clone https://github.com/tu-usuario/historico-clinico.git
cd historico-clinico

# Crear .env (mismo que en EC2)
nano .env

# Copiar docker-compose y nginx.conf modificados (del paso EC2)
# ...

# Iniciar servicios
docker-compose up -d
```

---

## 🌐 Configuración de Dominio

### Paso 1: Comprar dominio
- Registrar en: Namecheap, GoDaddy, etc.

### Paso 2: Apuntar nameservers
Para **DigitalOcean**:
- ns1.digitalocean.com
- ns2.digitalocean.com
- ns3.digitalocean.com

### Paso 3: Crear registros DNS
En el panel del proveedor:

```dns
A     hmed              TU_IP_VPS
A     www.hmed          TU_IP_VPS
CNAME hmed.midominio.com hmed.midominio.com
```

### Verificar DNS
```bash
# Verificar que DNS está apuntando
nslookup hmed.midominio.com
dig hmed.midominio.com +short
```

---

## 🔒 SSL/TLS con Let's Encrypt

### Opción 1: Certbot automático

```bash
# Generar certificado
sudo certbot certonly --standalone \
  -d hmed.midominio.com \
  -d www.hmed.midominio.com \
  --agree-tos \
  -m tu-email@example.com

# El certificado se guarda en:
# /etc/letsencrypt/live/hmed.midominio.com/

# Renovación automática (cron job)
# Verificar que el siguiente cronjob existe:
sudo crontab -l

# Si no existe, agregar:
# 0 2 * * * certbot renew --quiet
```

### Opción 2: Certbot con Nginx

```bash
# Si usas Nginx en el VPS:
sudo certbot --nginx \
  -d hmed.midominio.com \
  -d www.hmed.midominio.com
```

### Verificar certificado

```bash
# Ver fecha de expiración
sudo openssl x509 -in /etc/letsencrypt/live/hmed.midominio.com/cert.pem -text -noout | grep -A 2 "Validity"

# Hacer test de SSL
curl -I https://hmed.midominio.com
```

---

## 📊 Monitoreo y Mantenimiento

### 1️⃣ Logs y Debugging

```bash
# Ver logs de servicios
docker-compose logs -f web
docker-compose logs -f db
docker-compose logs -f nginx

# Ver logs específicos de Django
docker-compose exec web tail -f /var/log/django.log
```

### 2️⃣ Backups de Base de Datos

```bash
# Backup manual
docker-compose exec db pg_dump -U admin hmed_db > backup_$(date +%Y%m%d).sql

# Restaurar desde backup
docker-compose exec -T db psql -U admin hmed_db < backup_20240314.sql

# Backup automático (cron script)
```

**Crear archivo: `backup.sh`**

```bash
#!/bin/bash
BACKUP_DIR="/backups/hmed"
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p $BACKUP_DIR

# Backup DB
docker-compose -f /home/deploy/historico-clinico/docker-compose.yml \
  exec -T db pg_dump -U admin hmed_db | gzip > $BACKUP_DIR/hmed_$DATE.sql.gz

# Mantener solo los últimos 30 días
find $BACKUP_DIR -name "hmed_*.sql.gz" -mtime +30 -delete

echo "Backup completado: $BACKUP_DIR/hmed_$DATE.sql.gz"
```

```bash
# Agregar a cron (ejecutar cada día a las 2 AM)
0 2 * * * /home/deploy/backup.sh >> /var/log/hmed-backup.log 2>&1
```

### 3️⃣ Monitoreo de recursos

```bash
# Usar htop para monitoreo en tiempo real
sudo apt install htop
htop

# Monitoreo de Docker
docker stats

# Espacio en disco
df -h
du -sh /home/deploy/historico-clinico

# Estadísticas de red
netstat -an | grep ESTABLISHED | wc -l
```

### 4️⃣ Health checks

```bash
# Script de monitoreo
curl -s https://hmed.midominio.com/admin/login/ | grep -q "Login" && echo "✅ API OK" || echo "❌ API DOWN"
```

---

## ⏮️ Rollback y Recovery

### Rollback a versión anterior

```bash
# Listar imágenes disponibles
docker images

# Detener servicios
docker-compose down

# Usar imagen anterior
docker-compose run -e DEBUG=False web python manage.py migrate --no-input

# Iniciar con versión anterior
docker-compose up -d
```

### Recuperar Base de Datos Corrupta

```bash
# Conectar a BD y hacer dump
docker-compose exec db pg_dump -U admin hmed_db > recovery.sql

# Borrar BD corrupta
docker-compose exec db psql -U admin -c "DROP DATABASE hmed_db;"

# Recrear BD
docker-compose exec db psql -U admin -c "CREATE DATABASE hmed_db;"

# Restaurar desde backup
docker-compose exec -T db psql -U admin hmed_db < backup.sql
```

---

## 📋 Checklist de Despliegue

### Pre-Despliegue
- [ ] DEBUG=False en settings
- [ ] SECRET_KEY segura y unique
- [ ] ALLOWED_HOSTS configurado
- [ ] Base de datos externa (RDS, PostgreSQL)
- [ ] Dominio registrado
- [ ] SSL/TLS en transición
- [ ] Backups automatizados configurados
- [ ] Logs centralizados (CloudWatch, etc)

### Post-Despliegue
- [ ] Verificar HTTPS funciona
- [ ] Admin panel accesible en /admin
- [ ] API responde correctamente
- [ ] Frontend carga sin errores
- [ ] Emails funcionan (si aplica)
- [ ] Backups se ejecutan automáticamente
- [ ] Monitoreo activo
- [ ] CDN configurado (si aplica)

---

## 🔗 Referencias y Recursos

| Recurso | URL |
|---------|-----|
| AWS Documentation | https://docs.aws.amazon.com |
| Docker Compose Docs | https://docs.docker.com/compose |
| Let's Encrypt | https://letsencrypt.org |
| Nginx Docs | https://nginx.org/en/docs |
| DigitalOcean Tutorials | https://www.digitalocean.com/community/tutorials |

---

**Última actualización:** Marzo 2026  
**Versión:** 1.0.0
