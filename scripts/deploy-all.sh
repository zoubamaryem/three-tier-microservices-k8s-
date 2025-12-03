#!/bin/bash

echo "🚀 DÉPLOIEMENT APPLICATION MICROSERVICES"
echo "========================================"

cd ~/three-tier-microservices

# 1. Namespace
echo ""
echo "📦 [1/7] Création du namespace..."
kubectl apply -f k8s/namespace.yaml
sleep 2
echo "✅ Namespace créé"

# 2. Database
echo ""
echo "🗄️  [2/7] Déploiement Database..."
kubectl apply -f k8s/database/secret.yaml
kubectl apply -f k8s/database/configmap.yaml
kubectl apply -f k8s/database/pvc.yaml
kubectl apply -f k8s/database/statefulset.yaml
kubectl apply -f k8s/database/service.yaml

echo "⏳ Attente du démarrage de PostgreSQL (60s)..."
kubectl wait --for=condition=ready pod -l app=postgres -n microservices-app --timeout=120s 2>/dev/null || sleep 60
echo "✅ Database déployée"

# 3. Users Service
echo ""
echo "👥 [3/7] Déploiement Users Service..."
kubectl apply -f k8s/users-service/deployment.yaml
kubectl apply -f k8s/users-service/service.yaml
kubectl apply -f k8s/users-service/hpa.yaml

echo "⏳ Attente Users Service (30s)..."
sleep 30
echo "✅ Users Service déployé"

# 4. Posts Service
echo ""
echo "📝 [4/7] Déploiement Posts Service..."
kubectl apply -f k8s/posts-service/deployment.yaml
kubectl apply -f k8s/posts-service/service.yaml
kubectl apply -f k8s/posts-service/hpa.yaml

echo "⏳ Attente Posts Service (30s)..."
sleep 30
echo "✅ Posts Service déployé"

# 5. API Gateway
echo ""
echo "🌐 [5/7] Déploiement API Gateway..."
kubectl apply -f k8s/api-gateway/deployment.yaml
kubectl apply -f k8s/api-gateway/service.yaml

echo "⏳ Attente Gateway (20s)..."
sleep 20
echo "✅ API Gateway déployé"

# 6. Frontend
echo ""
echo "🖥️  [6/7] Déploiement Frontend..."
kubectl apply -f k8s/frontend/deployment.yaml
kubectl apply -f k8s/frontend/service.yaml

echo "⏳ Attente Frontend (20s)..."
sleep 20
echo "✅ Frontend déployé"

# 7. Vérifications
echo ""
echo "🔍 [7/7] Vérifications finales..."
sleep 10

echo ""
echo "========================================"
echo "✅ DÉPLOIEMENT TERMINÉ"
echo "========================================"

echo ""
echo "📊 État des pods:"
kubectl get pods -n microservices-app -o wide

echo ""
echo "🌐 Services:"
kubectl get svc -n microservices-app

echo ""
echo "🔗 HPAs:"
kubectl get hpa -n microservices-app

echo ""
echo "========================================"
echo "🌐 ACCÈS À L'APPLICATION"
echo "========================================"
echo ""
echo "   Frontend: http://192.168.56.10:30080"
echo ""
echo "========================================"
echo "🧪 TESTS DES MICROSERVICES"
echo "========================================"
echo ""
echo "# Health checks"
echo "kubectl exec -it deploy/api-gateway -n microservices-app -- wget -qO- http://users-service:5001/health"
echo "kubectl exec -it deploy/api-gateway -n microservices-app -- wget -qO- http://posts-service:5002/health"
echo ""
echo "# Via Gateway"
echo "kubectl exec -it deploy/api-gateway -n microservices-app -- wget -qO- http://localhost:8080/api/users"
echo "kubectl exec -it deploy/api-gateway -n microservices-app -- wget -qO- http://localhost:8080/api/posts"
echo ""
echo "========================================"
echo "📝 COMMANDES UTILES"
echo "========================================"
echo ""
echo "# Voir tous les pods"
echo "kubectl get pods -n microservices-app"
echo ""
echo "# Logs Users Service"
echo "kubectl logs -l app=users-service -n microservices-app -f"
echo ""
echo "# Logs Posts Service"
echo "kubectl logs -l app=posts-service -n microservices-app -f"
echo ""
echo "# Logs API Gateway"
echo "kubectl logs -l app=api-gateway -n microservices-app -f"
echo ""
echo "# Logs Frontend"
echo "kubectl logs -l app=frontend -n microservices-app -f"
echo ""
echo "# Redémarrer un service"
echo "kubectl rollout restart deployment/users-service -n microservices-app"
echo ""
