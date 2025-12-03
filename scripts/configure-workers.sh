#!/bin/bash

echo "🔧 CONFIGURATION DES WORKERS POUR LE REGISTRE"
echo "=============================================="

# Configuration K3s
read -r -d '' K3S_CONFIG <<'CONFIGEOF'
mirrors:
  "192.168.56.10:5000":
    endpoint:
      - "http://192.168.56.10:5000"
configs:
  "192.168.56.10:5000":
    tls:
      insecure_skip_verify: true
CONFIGEOF

# Worker1
echo ""
echo "🔨 Configuration de worker1..."
ssh worker1 <<SSHEOF
sudo mkdir -p /etc/rancher/k3s
echo '$K3S_CONFIG' | sudo tee /etc/rancher/k3s/registries.yaml > /dev/null
sudo systemctl restart k3s-agent
sleep 5
sudo systemctl status k3s-agent --no-pager
SSHEOF

if [ $? -eq 0 ]; then
    echo "✅ Worker1 configuré"
else
    echo "❌ Erreur worker1"
    exit 1
fi

# Worker2
echo ""
echo "🔨 Configuration de worker2..."
ssh worker2 <<SSHEOF
sudo mkdir -p /etc/rancher/k3s
echo '$K3S_CONFIG' | sudo tee /etc/rancher/k3s/registries.yaml > /dev/null
sudo systemctl restart k3s-agent
sleep 5
sudo systemctl status k3s-agent --no-pager
SSHEOF

if [ $? -eq 0 ]; then
    echo "✅ Worker2 configuré"
else
    echo "❌ Erreur worker2"
    exit 1
fi

echo ""
echo "=============================================="
echo "✅ TOUS LES WORKERS SONT CONFIGURÉS"
echo "=============================================="

echo ""
echo "Maintenant, redémarrer les pods:"
echo "  kubectl delete pods --all -n microservices-app"
