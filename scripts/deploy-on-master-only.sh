#!/bin/bash

echo "🎯 DÉPLOIEMENT SUR LE MASTER UNIQUEMENT"
echo "========================================"

# Fonction pour ajouter nodeSelector
add_node_selector() {
    local file=$1
    
    # Vérifier si nodeSelector existe déjà
    if grep -q "nodeSelector" "$file"; then
        echo "  ⏭️  NodeSelector déjà présent dans $file"
        return
    fi
    
    # Ajouter nodeSelector après "spec:" dans le template pod
    # Chercher la ligne avec "spec:" qui suit "template:"
    awk '
    /template:/ { in_template=1 }
    in_template && /^      containers:/ { 
        print "      nodeSelector:"
        print "        kubernetes.io/hostname: ubuntu-master"
        in_template=0
    }
    { print }
    ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
    
    echo "  ✅ NodeSelector ajouté à $file"
}

# Modifier tous les deployments
echo ""
echo "📝 Modification des deployments..."

add_node_selector "k8s/users-service/deployment.yaml"
add_node_selector "k8s/posts-service/deployment.yaml"
add_node_selector "k8s/api-gateway/deployment.yaml"
add_node_selector "k8s/frontend/deployment.yaml"

# Modifier aussi le StatefulSet
echo ""
echo "📝 Modification du StatefulSet..."
add_node_selector "k8s/database/statefulset.yaml"

echo ""
echo "========================================"
echo "✅ TOUS LES FICHIERS MODIFIÉS"
echo "========================================"

echo ""
echo "🗑️  Suppression de l'ancien déploiement..."
kubectl delete namespace microservices-app

echo "⏳ Attente de la suppression..."
sleep 15

echo ""
echo "🚀 Nouveau déploiement..."
./scripts/deploy-all.sh

echo ""
echo "========================================"
echo "✅ DÉPLOIEMENT TERMINÉ SUR LE MASTER"
echo "========================================"
