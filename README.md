# 🏗️ Three-Tier Microservices Application on Kubernetes

[![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)
[![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white)](https://www.postgresql.org/)
[![Flask](https://img.shields.io/badge/Flask-000000?style=for-the-badge&logo=flask&logoColor=white)](https://flask.palletsprojects.com/)
[![Nginx](https://img.shields.io/badge/Nginx-009639?style=for-the-badge&logo=nginx&logoColor=white)](https://nginx.org/)

Une application **production-ready** démontrant une architecture **Three-Tier** avec **2 microservices communiquants** déployés sur **Kubernetes**.

![Architecture](screenshots/15-architecture-diagram.png)

---

## 📋 Table des Matières

- [🎯 Objectif du Projet](#-objectif-du-projet)
- [🏗️ Architecture](#️-architecture)
- [✨ Fonctionnalités](#-fonctionnalités)
- [🛠️ Technologies Utilisées](#️-technologies-utilisées)
- [📦 Composants Kubernetes](#-composants-kubernetes)
- [🚀 Déploiement](#-déploiement)
- [🧪 Tests](#-tests)
- [📊 Captures d'Écran](#-captures-décran)
- [🎓 Concepts Kubernetes Appliqués](#-concepts-kubernetes-appliqués)
- [🔐 Bonnes Pratiques](#-bonnes-pratiques)
- [📚 Documentation](#-documentation)

---

## 🎯 Objectif du Projet

Ce projet démontre la maîtrise de :
- ✅ **Architecture Microservices** avec communication inter-services
- ✅ **Kubernetes** (K3s) pour l'orchestration de containers
- ✅ **Docker** pour la conteneurisation
- ✅ **CI/CD** avec scripts automatisés
- ✅ **Bonnes pratiques DevOps** (IaC, HA, Security)

---

## 🏗️ Architecture

### Vue d'Ensemble
```
┌─────────────────────────────────────────────────────────────┐
│                    TIER 1 : PRÉSENTATION                    │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  FRONTEND (Nginx + HTML/CSS/JavaScript)              │  │
│  │  - Interface utilisateur web                         │  │
│  │  - Reverse proxy intégré                             │  │
│  │  - NodePort 30080 (accessible publiquement)          │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────┬───────────────────────────────────┘
                          │
          ┌───────────────┴───────────────┐
          │                               │
┌─────────▼─────────────┐   ┌─────────────▼──────────────┐
│   TIER 2a : LOGIQUE   │   │   TIER 2b : LOGIQUE        │
│                       │   │                            │
│ 🔷 MICROSERVICE 1     │◄──┤ 🔶 MICROSERVICE 2          │
│ Users Service         │   │ Posts Service              │
│ - Gestion users       │   │ - Gestion posts            │
│ - CRUD utilisateurs   │   │ - CRUD posts               │
│ - Port 5001           │   │ - Communication avec MS1 🔗│
│ - Flask + PostgreSQL  │   │ - Port 5002                │
└───────────┬───────────┘   └────────────┬───────────────┘
            │                            │
            └──────────┬─────────────────┘
                       │
          ┌────────────▼─────────────┐
          │   TIER 3 : DONNÉES       │
          │                          │
          │  PostgreSQL StatefulSet  │
          │  - Tables: users, posts  │
          │  - PVC (stockage 5Gi)    │
          │  - Port 5432             │
          └──────────────────────────┘
```

### Communication Inter-Microservices

Le **Posts Service** communique avec le **Users Service** avant de créer un post :
```python
# Posts Service appelle Users Service
response = requests.get(f"http://users-service:5001/users/{user_id}")

if response.status_code == 200:
    # Utilisateur existe, créer le post
    user_data = response.json()
    create_post(user_id, title, content, user_data)
else:
    # Utilisateur n'existe pas, retourner erreur
    return {"error": "User not found"}, 404
```

---

## ✨ Fonctionnalités

### Microservice 1 : Users Service
- ✅ Créer un utilisateur (POST /users)
- ✅ Lister tous les utilisateurs (GET /users)
- ✅ Récupérer un utilisateur (GET /users/{id})
- ✅ Modifier un utilisateur (PUT /users/{id})
- ✅ Supprimer un utilisateur (DELETE /users/{id})
- ✅ Statistiques (GET /users/stats)

### Microservice 2 : Posts Service
- ✅ Créer un post avec validation utilisateur (POST /posts)
- ✅ Lister tous les posts avec infos enrichies (GET /posts)
- ✅ Posts par utilisateur (GET /posts/user/{user_id})
- ✅ Récupérer un post (GET /posts/{id})
- ✅ Modifier un post (PUT /posts/{id})
- ✅ Supprimer un post (DELETE /posts/{id})
- ✅ **Communication avec Users Service** pour vérification

### Frontend
- ✅ Interface web responsive
- ✅ Gestion des utilisateurs
- ✅ Gestion des posts
- ✅ Validation en temps réel
- ✅ Indicateurs de statut des services

---

## 🛠️ Technologies Utilisées

| Composant | Technologie | Version |
|-----------|-------------|---------|
| **Orchestration** | Kubernetes (K3s) | v1.33+ |
| **Conteneurs** | Docker | 20.10+ |
| **Backend** | Python Flask | 3.0 |
| **Database** | PostgreSQL | 15 |
| **Frontend** | HTML/CSS/JS + Nginx | Alpine |
| **Proxy** | Nginx | Alpine |
| **IaC** | YAML | - |

---

## 📦 Composants Kubernetes

### Deployments
- `users-service` : 2 replicas (scalable 2-5)
- `posts-service` : 2 replicas (scalable 2-5)
- `api-gateway` : 2 replicas
- `frontend` : 2 replicas

### StatefulSet
- `postgres` : 1 replica avec PVC de 5Gi

### Services
- `users-service` : ClusterIP (5001)
- `posts-service` : ClusterIP (5002)
- `api-gateway` : ClusterIP (8080)
- `frontend` : NodePort (30080)
- `postgres-service` : ClusterIP (5432)
- `postgres-headless` : Headless

### ConfigMaps & Secrets
- `postgres-config` : Configuration DB
- `postgres-secret` : Credentials (base64)
- `postgres-init-sql` : Script d'initialisation

### HPA (HorizontalPodAutoscaler)
- Auto-scaling basé sur CPU (70%)
- Min: 2 replicas, Max: 5 replicas

---

## 🚀 Déploiement

### Prérequis
```bash
# Kubernetes (K3s recommandé)
curl -sfL https://get.k3s.io | sh -

# Docker
sudo apt install docker.io -y

# kubectl configuré
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
```

### Installation Rapide
```bash
# Cloner le repo
git clone https://github.com/votre-username/three-tier-microservices.git
cd three-tier-microservices

# Build et Push des images
./scripts/build-all.sh

# Déploiement
./scripts/deploy-all.sh

# Vérification
kubectl get all -n microservices-app
```

### Accès à l'Application
```
Frontend : http://<MASTER_IP>:30080
API Users : http://<MASTER_IP>:30080/api/users
API Posts : http://<MASTER_IP>:30080/api/posts
```

---

## 🧪 Tests

### Test Manuel
```bash
# Health check
curl http://192.168.56.10:30080/api/users

# Créer un utilisateur
curl -X POST http://192.168.56.10:30080/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@example.com"}'

# Créer un post (teste la communication inter-microservices)
curl -X POST http://192.168.56.10:30080/api/posts \
  -H "Content-Type: application/json" \
  -d '{"user_id":1,"title":"Test","content":"Communication entre microservices"}'
```

### Test de Persistance
```bash
# Supprimer le pod postgres
kubectl delete pod postgres-0 -n microservices-app

# Vérifier que les données persistent après redémarrage
kubectl get pods -n microservices-app -w
curl http://192.168.56.10:30080/api/users
```

### Test de Scalabilité
```bash
# Voir les HPA
kubectl get hpa -n microservices-app

# Générer de la charge (optionnel)
kubectl run -i --tty load-generator --rm --image=busybox --restart=Never -- /bin/sh
while sleep 0.01; do wget -q -O- http://frontend-service; done
```

---

## 📊 Captures d'Écran

### Pods en Exécution
![Pods Running](screenshots/01-pods-running.png)

### Services Kubernetes
![Services](screenshots/02-services.png)

### Interface Web - Utilisateurs
![Users List](screenshots/07-users-list.png)

### Interface Web - Posts
![Posts List](screenshots/08-posts-list.png)

### Communication Inter-Microservices (Logs)
![Communication Logs](screenshots/12-logs-communication.png)

### API Response - Users
![API Users](screenshots/13-api-users.png)

### API Response - Posts
![API Posts](screenshots/14-api-posts.png)

---

## 🎓 Concepts Kubernetes Appliqués

| Concept | Implémentation |
|---------|----------------|
| **Namespace** | Isolation de l'application (`microservices-app`) |
| **Deployment** | Microservices, Frontend, Gateway |
| **StatefulSet** | PostgreSQL avec identité stable |
| **Service (ClusterIP)** | Communication interne entre pods |
| **Service (NodePort)** | Exposition publique du Frontend |
| **ConfigMap** | Configuration non-sensible |
| **Secret** | Credentials chiffrés |
| **PVC/PV** | Stockage persistant pour PostgreSQL |
| **HPA** | Auto-scaling automatique |
| **Liveness Probe** | Détection de pods défaillants |
| **Readiness Probe** | Contrôle du trafic vers pods sains |
| **Resource Limits** | CPU et mémoire définis |
| **Labels & Selectors** | Organisation et routing |
| **NodeSelector** | Placement de pods sur nodes spécifiques |

---

## 🔐 Bonnes Pratiques

### Sécurité
- ✅ **Secrets** pour credentials sensibles
- ✅ **Services ClusterIP** : Microservices non exposés publiquement
- ✅ **Principe du moindre privilège** : Pas de root dans les containers
- ✅ **Network Policies** : Contrôle du trafic inter-pods

### Haute Disponibilité
- ✅ **Réplication** : Minimum 2 replicas par service
- ✅ **StatefulSet** : Pour la base de données
- ✅ **PersistentVolume** : Données persistantes
- ✅ **Health Checks** : Détection et redémarrage automatique

### Scalabilité
- ✅ **HPA** : Auto-scaling basé sur métriques
- ✅ **Microservices** : Services indépendants scalables séparément
- ✅ **Stateless Design** : Pas d'état local dans les apps

### Observabilité
- ✅ **Logging structuré** : Tous les événements loggés
- ✅ **Health endpoints** : `/health` et `/ready`
- ✅ **Resource monitoring** : Métriques CPU/RAM

---

## 📚 Documentation

### Structure du Projet
```
three-tier-microservices/
├── frontend/
│   ├── index.html              # Interface web
│   ├── nginx.conf              # Config reverse proxy
│   └── Dockerfile
├── users-service/
│   ├── users_service.py        # Microservice 1
│   ├── requirements.txt
│   └── Dockerfile
├── posts-service/
│   ├── posts_service.py        # Microservice 2
│   ├── requirements.txt
│   └── Dockerfile
├── api-gateway/
│   ├── nginx.conf              # Routage
│   └── Dockerfile
├── k8s/
│   ├── namespace.yaml
│   ├── database/               # StatefulSet, PVC, Services
│   ├── users-service/          # Deployment, Service, HPA
│   ├── posts-service/          # Deployment, Service, HPA
│   ├── api-gateway/            # Deployment, Service
│   └── frontend/               # Deployment, Service
├── scripts/
│   ├── build-all.sh            # Build toutes les images
│   ├── deploy-all.sh           # Déploiement complet
│   └── cleanup.sh              # Nettoyage
├── screenshots/                # Captures d'écran
└── README.md
```

### Endpoints API

#### Users Service (Port 5001)

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/health` | Health check |
| GET | `/ready` | Readiness check |
| GET | `/users` | Liste tous les utilisateurs |
| GET | `/users/{id}` | Récupère un utilisateur |
| POST | `/users` | Crée un utilisateur |
| PUT | `/users/{id}` | Modifie un utilisateur |
| DELETE | `/users/{id}` | Supprime un utilisateur |
| GET | `/users/stats` | Statistiques |

#### Posts Service (Port 5002)

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/health` | Health check |
| GET | `/ready` | Readiness check (+ check Users Service) |
| GET | `/posts` | Liste tous les posts |
| GET | `/posts/{id}` | Récupère un post |
| GET | `/posts/user/{user_id}` | Posts d'un utilisateur |
| POST | `/posts` | Crée un post (vérifie user) |
| PUT | `/posts/{id}` | Modifie un post |
| DELETE | `/posts/{id}` | Supprime un post |
| GET | `/posts/stats` | Statistiques |

---

## 🤝 Contributions

Les contributions sont les bienvenues ! N'hésitez pas à :
- 🐛 Reporter des bugs
- 💡 Proposer des améliorations
- 📖 Améliorer la documentation
- ⭐ Star le projet si vous l'aimez !

---

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier [LICENSE](LICENSE) pour plus de détails.

---

## 👤 Auteur

**Votre Nom**
- GitHub: [@votre-username](https://github.com/votre-username)
- Email: votre.email@example.com

---

## 🙏 Remerciements

- Kubernetes Documentation
- Flask Documentation
- PostgreSQL Documentation
- Communauté DevOps

---

## 📈 Statistiques du Projet

- **Lignes de code** : ~2000+
- **Fichiers Kubernetes** : 20+
- **Microservices** : 2
- **Technologies** : 6+
- **Temps de développement** : X semaines

---

<div align="center">

**⭐ Si ce projet vous a été utile, n'oubliez pas de lui donner une étoile ! ⭐**

Made with ❤️ and ☕

</div>
