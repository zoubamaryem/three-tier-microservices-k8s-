#!/bin/bash

echo "🔨 BUILD DE TOUTES LES IMAGES DOCKER"
echo "===================================="

cd ~/three-tier-microservices

# Configurer Docker pour registre insecure
echo ""
echo "🐳 Configuration Docker..."
if ! grep -q "192.168.56.10:5000" /etc/docker/daemon.json 2>/dev/null; then
    sudo tee /etc/docker/daemon.json > /dev/null <<DOCKER_EOF
{
  "insecure-registries": ["192.168.56.10:5000", "localhost:5000"]
}
DOCKER_EOF
    sudo systemctl restart docker
    sleep 5
    echo "✅ Docker configuré"
else
    echo "✅ Docker déjà configuré"
fi

# Démarrer le registre
docker start registry 2>/dev/null || docker run -d -p 5000:5000 --restart=always --name registry registry:2
sleep 3
echo "✅ Registre actif"

# Build Users Service
echo ""
echo "🔨 [1/4] Build Users Service..."
cd users-service
docker build -t 192.168.56.10:5000/users-service:latest . 
if [ $? -eq 0 ]; then
    docker push 192.168.56.10:5000/users-service:latest
    echo "✅ Users Service construit et poussé"
else
    echo "❌ Erreur build Users Service"
    exit 1
fi
cd ..

# Build Posts Service
echo ""
echo "🔨 [2/4] Build Posts Service..."
cd posts-service
docker build -t 192.168.56.10:5000/posts-service:latest .
if [ $? -eq 0 ]; then
    docker push 192.168.56.10:5000/posts-service:latest
    echo "✅ Posts Service construit et poussé"
else
    echo "❌ Erreur build Posts Service"
    exit 1
fi
cd ..

# Build API Gateway
echo ""
echo "🔨 [3/4] Build API Gateway..."
cd api-gateway
docker build -t 192.168.56.10:5000/api-gateway:latest .
if [ $? -eq 0 ]; then
    docker push 192.168.56.10:5000/api-gateway:latest
    echo "✅ API Gateway construit et poussé"
else
    echo "❌ Erreur build API Gateway"
    exit 1
fi
cd ..

# Build Frontend
echo ""
echo "🔨 [4/4] Build Frontend..."
cd frontend
docker build -t 192.168.56.10:5000/frontend:latest .
if [ $? -eq 0 ]; then
    docker push 192.168.56.10:5000/frontend:latest
    echo "✅ Frontend construit et poussé"
else
    echo "❌ Erreur build Frontend"
    exit 1
fi
cd ..

echo ""
echo "===================================="
echo "✅ TOUTES LES IMAGES SONT PRÊTES"
echo "===================================="

echo ""
echo "📦 Images disponibles:"
docker images | grep 192.168.56.10:5000
