#!/bin/bash

echo "📸 CAPTURE D'ÉCRAN AUTOMATIQUE"
echo "=============================="

SCREENSHOT_DIR="screenshots"
mkdir -p $SCREENSHOT_DIR

echo ""
echo "⚠️  IMPORTANT: Ce script génère les commandes."
echo "   Vous devez prendre les captures manuellement."
echo ""

# Générer fichier avec toutes les commandes
cat > /tmp/screenshot-commands.txt << 'COMMANDS'
# CAPTURES TERMINAL

## 01 - Pods Running
kubectl get pods -n microservices-app -o wide
# Screenshot: screenshots/01-pods-running.png

## 02 - Services
kubectl get svc -n microservices-app
# Screenshot: screenshots/02-services.png

## 03 - All Resources
kubectl get all -n microservices-app
# Screenshot: screenshots/03-all-resources.png

## 04 - PVC
kubectl get pvc -n microservices-app
# Screenshot: screenshots/04-pvc.png

## 05 - HPA
kubectl get hpa -n microservices-app
# Screenshot: screenshots/05-hpa.png

## 12 - Logs Communication
kubectl logs -l app=posts-service -n microservices-app --tail=30
# Screenshot: screenshots/12-logs-communication.png

## 13 - API Users
curl http://192.168.56.10:30080/api/users | python3 -m json.tool
# Screenshot: screenshots/13-api-users.png

## 14 - API Posts
curl http://192.168.56.10:30080/api/posts | python3 -m json.tool
# Screenshot: screenshots/14-api-posts.png

# CAPTURES WEB (dans le navigateur)

## 06 - Frontend Home
URL: http://192.168.56.10:30080
# Screenshot: screenshots/06-frontend-home.png

## 07 - Users List
URL: http://192.168.56.10:30080 (onglet Utilisateurs)
# Screenshot: screenshots/07-users-list.png

## 08 - Posts List
URL: http://192.168.56.10:30080 (onglet Posts)
# Screenshot: screenshots/08-posts-list.png

## 09 - Create User
Remplir le formulaire utilisateur
# Screenshot: screenshots/09-create-user.png

## 10 - Create Post
Remplir le formulaire post
# Screenshot: screenshots/10-create-post.png

## 11 - Post with User Info
Voir le post créé avec infos utilisateur
# Screenshot: screenshots/11-post-with-user-info.png

COMMANDS

cat /tmp/screenshot-commands.txt

echo ""
echo "=============================="
echo "✅ Liste des captures générée dans:"
echo "   /tmp/screenshot-commands.txt"
echo ""
echo "📝 Instructions:"
echo "   1. Exécute chaque commande"
echo "   2. Prends la capture d'écran"
echo "   3. Sauvegarde dans screenshots/"
echo ""
