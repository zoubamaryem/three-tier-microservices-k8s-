#!/bin/bash

echo "🚀 BUILD + DEPLOY COMPLET"
echo "========================="

cd ~/three-tier-microservices

# 1. Build
echo ""
echo "ÉTAPE 1: BUILD DES IMAGES"
./scripts/build-all.sh

if [ $? -ne 0 ]; then
    echo "❌ Erreur lors du build"
    exit 1
fi

# 2. Deploy
echo ""
echo ""
echo "ÉTAPE 2: DÉPLOIEMENT SUR KUBERNETES"
./scripts/deploy-all.sh

echo ""
echo "========================="
echo "✅ TOUT EST TERMINÉ !"
echo "========================="
