# Système de Gestion de Boutique - Microservices

Ce projet implémente un système de gestion de boutique basé sur une architecture microservices avec deux services Node.js/Express qui communiquent via Kubernetes.

## Architecture

- **Service d'Inventaire** : Gestionnaire d'inventaire qui consulte le catalogue de produits
- **Service de Produits** : Gestionnaire du catalogue de produits avec données simulées

## Services

### Service d'Inventaire (Port 4000)

- `GET /inventory` : Récupère l'inventaire complet avec informations de stock
- `GET /inventory/:id` : Vérifie le stock d'un produit spécifique
- `GET /health` : Vérification de l'état du service et des dépendances

### Service de Produits (Port 5000)

- `GET /products` : Catalogue complet des produits disponibles
- `GET /products/:id` : Détails d'un produit spécifique
- `GET /health` : Vérification de l'état du service

## Développement Local

### Service d'Inventaire

```bash
cd inventory-service
npm install
npm start
```

### Service de Produits

```bash
cd product-service
npm install
npm start
```

## Docker

### Construire les images

```bash
# Service de Produits
cd product-service
docker build -t product-service:latest .

# Service d'Inventaire
cd inventory-service
docker build -t inventory-service:latest .
```

### Exécuter avec Docker

```bash
# Service de Produits (doit être démarré en premier)
docker run -p 5000:5000 --name product-service product-service:latest

# Service d'Inventaire (dans un autre terminal)
docker run -p 4000:4000 --name inventory-service --link product-service inventory-service:latest
```

## Kubernetes avec k3s

### Déploiement avec k3s

Utilisez le script de déploiement :

```bash
./deploy.sh
```

Ce script :

- Construit les images Docker localement
- Les importe dans k3s
- Déploie les services sur le cluster

Les services communiquent via DNS Kubernetes :

- Le Service d'Inventaire appelle le Service de Produits via `http://product-service:5000`
- La résolution DNS Kubernetes permet cette communication inter-services

### Monitoring et Health Checks

Les deux services utilisent des sondes Kubernetes avancées :

- **readinessProbe** : Vérifie si le pod est prêt (endpoint `/health`, délai 8s, période 6s)
- **livenessProbe** : Vérifie la santé du pod (endpoint `/health`, délai 35s, période 12s)

## Tests et Validation

### Tests automatisés

```bash
./test.sh
```

### Tests manuels

Accès au Service d'Inventaire :

```bash
kubectl port-forward service/inventory-service 4000:4000

# Dans un autre terminal
curl http://localhost:4000/inventory          # Inventaire complet
curl http://localhost:4000/inventory/1        # Stock d'un produit
curl http://localhost:4000/health             # Health check
```

Accès au Service de Produits :

```bash
kubectl port-forward service/product-service 5000:5000

# Dans un autre terminal
curl http://localhost:5000/products           # Catalogue complet
curl http://localhost:5000/products/2         # Produit spécifique
curl http://localhost:5000/health             # Health check
```

## Structure du projet

```
.
├── inventory-service/        # Service de gestion d'inventaire
│   ├── server.js            # API Express avec logique métier
│   ├── package.json         # Dépendances (express, axios)
│   └── Dockerfile           # Image Docker
├── product-service/         # Service de catalogue produits
│   ├── server.js            # API Express avec données simulées
│   ├── package.json         # Dépendances (express)
│   └── Dockerfile           # Image Docker
├── k8s/                     # Manifestes Kubernetes
│   ├── inventory-service.yaml   # Deployment + Service pour Inventaire
│   └── product-service.yaml    # Deployment + Service pour Produits
├── deploy.sh                # Script de déploiement k3s
├── test.sh                  # Script de test automatisé
├── cleanup.sh               # Script de nettoyage
└── README.md                # Documentation
```

## Données Simulées

Le système inclut des données de démonstration :

- 4 produits avec stocks variés (Electronics, Furniture)
- Informations d'entrepôt (Paris, gestionnaire)
- Calculs de valeur d'inventaire automatiques
- Statuts de stock intelligents (En stock, Stock limité, Rupture)

## Configuration

### Ports utilisés

- **Service d'Inventaire**: 4000
- **Service de Produits**: 5000

### Variables d'environnement

- `PRODUCT_SERVICE_URL`: URL du service de produits (défaut: `http://product-service:5000`)
- `PORT`: Port d'écoute des services

## Prérequis

- Node.js 18+
- Docker
- kubectl
- Cluster Kubernetes (k3s recommandé pour le développement local)

## Nettoyage

Pour supprimer les ressources déployées :

```bash
./cleanup.sh
```

## Fonctionnalités Avancées

- **Haute disponibilité** : 3 réplicas pour les produits, 2 pour l'inventaire
- **Monitoring** : Health checks complets avec vérification des dépendances
- **Gestion d'erreurs** : Réponses détaillées en cas d'indisponibilité
- **Données enrichies** : Calculs automatiques de valeur d'inventaire
- **Ressources optimisées** : Limites CPU/mémoire configurées
