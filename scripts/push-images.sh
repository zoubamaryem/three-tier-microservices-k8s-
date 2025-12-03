#!/bin/bash

echo "📤 PUSH DES IMAGES VERS LE REGISTRE"
echo "===================================="

# Vérifier que le registre répond
echo ""
echo "🔍 Vérification du registre..."
if curl -f -s http://192.168.56.10:5000/v2/_catalog > /dev/null; then
    echo "✅ Registre accessible"
else
    echo "❌ Registre inaccessible, configuration Docker..."
    
    sudo tee /etc/docker/daemon.json > /dev/null <<DOCKEREOF
{
  "insecure-registries": ["192.168.56.10:5000", "localhost:5000"]
}
DOCKEREOF
    
    sudo systemctl restart docker
    sleep 10
    docker start registry
    sleep 5
fi

# Push des images
echo ""
echo "📤 Push des images..."

echo "[1/4] Users Service..."
docker push 192.168.56.10:5000/users-service:latest
if [ $? -eq 0 ]; then
    echo "✅ Users Service → OK"
else
    echo "❌ Échec Users Service"
    exit 1
fi

echo "[2/4] Posts Service..."
docker push 192.168.56.10:5000/posts-service:latest
if [ $? -eq 0 ]; then
    echo "✅ Posts Service → OK"
else
    echo "❌ Échec Posts Service"
    exit 1
fi

echo "[3/4] API Gateway..."
docker push 192.168.56.10:5000/api-gateway:latest
if [ $? -eq 0 ]; then
    echo "✅ API Gateway → OK"
else
    echo "❌ Échec API Gateway"
    exit 1
fi

echo "[4/4] Frontend..."
docker push 192.168.56.10:5000/frontend:latest
if [ $? -eq 0 ]; then
    echo "✅ Frontend → OK"
else
    echo "❌ Échec Frontend"
    exit 1
fi

echo ""
echo "===================================="
echo "✅ TOUTES LES IMAGES SONT POUSSÉES"
echo "===================================="

echo ""
echo "📦 Contenu du registre:"
curl -s http://192.168.56.10:5000/v2/_catalog | python3 -m json.tool

echo ""
echo "Prêt pour le déploiement:"
echo "  kubectl delete namespace microservices-app"
echo "  ./scripts/deploy-all.sh"
