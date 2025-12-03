#!/bin/bash

echo "🔧 CORRECTION K3S + REGISTRE"
echo "============================="

# 1. Configuration K3s
echo ""
echo "📝 Configuration K3s pour registre insecure..."
sudo mkdir -p /etc/rancher/k3s

sudo tee /etc/rancher/k3s/registries.yaml > /dev/null <<CONFIGEOF
mirrors:
  "192.168.56.10:5000":
    endpoint:
      - "http://192.168.56.10:5000"
  "localhost:5000":
    endpoint:
      - "http://localhost:5000"
configs:
  "192.168.56.10:5000":
    tls:
      insecure_skip_verify: true
  "localhost:5000":
    tls:
      insecure_skip_verify: true
CONFIGEOF

echo "✅ Configuration créée"

# 2. Redémarrer K3s
echo ""
echo "🔄 Redémarrage K3s..."
sudo systemctl restart k3s

echo "⏳ Attente du redémarrage (30s)..."
sleep 30

# 3. Vérifier
echo ""
echo "🔍 Vérification..."
kubectl get nodes

if [ $? -eq 0 ]; then
    echo "✅ K3s fonctionne"
else
    echo "❌ K3s ne répond pas"
    echo "Logs K3s:"
    sudo journalctl -u k3s -n 20 --no-pager
    exit 1
fi

# 4. Supprimer les anciens pods
echo ""
echo "🗑️  Suppression des anciens pods..."
kubectl delete pods --all -n microservices-app

echo ""
echo "⏳ Attente du redémarrage des pods (60s)..."
sleep 60

# 5. État final
echo ""
echo "============================="
echo "📊 ÉTAT FINAL"
echo "============================="
kubectl get pods -n microservices-app -o wide

echo ""
echo "Si tous les pods sont Running:"
echo "  - Frontend: http://192.168.56.10:30080"
echo "  - Tests: ./scripts/test-app.sh"
