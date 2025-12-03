#!/bin/bash

echo "🧹 NETTOYAGE COMPLET"
echo "==================="

echo ""
echo "Suppression du namespace microservices-app..."
kubectl delete namespace microservices-app

echo ""
echo "✅ Nettoyage terminé"
echo ""
echo "Pour supprimer aussi les images Docker:"
echo "  docker rmi 192.168.56.10:5000/users-service:latest"
echo "  docker rmi 192.168.56.10:5000/posts-service:latest"
echo "  docker rmi 192.168.56.10:5000/api-gateway:latest"
echo "  docker rmi 192.168.56.10:5000/frontend:latest"
