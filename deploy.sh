#!/bin/bash

set -e

echo "Déploiement du Système de Gestion de Boutique avec k3s..."

# Vérifier si Docker est disponible
if ! command -v docker &> /dev/null; then
    echo "Erreur: Docker n'est pas installé ou n'est pas dans le PATH"
    exit 1
fi

# Vérifier si k3s est installé
if ! command -v k3s &> /dev/null; then
    echo "Erreur: k3s n'est pas installé. Installez-le avec: curl -sfL https://get.k3s.io | sh -"
    exit 1
fi

# Vérifier si kubectl est disponible
if ! command -v kubectl &> /dev/null; then
    echo "Erreur: kubectl n'est pas installé ou n'est pas dans le PATH"
    exit 1
fi

# Fonction pour importer une image dans k3s
import_image_to_k3s() {
    local image_name=$1
    echo "Importation de l'image $image_name dans k3s..."
    
    # Sauvegarder l'image Docker
    docker save $image_name > /tmp/${image_name//[:\/]/_}.tar
    
    # Importer dans k3s
    sudo k3s ctr images import /tmp/${image_name//[:\/]/_}.tar
    
    # Nettoyer le fichier temporaire
    rm -f /tmp/${image_name//[:\/]/_}.tar
}

# Construire les images Docker
echo "Construction de l'image Docker pour le Service de Produits..."
cd product-service
docker build -t product-service:latest .
import_image_to_k3s "product-service:latest"
cd ..

echo "Construction de l'image Docker pour le Service d'Inventaire..."
cd inventory-service
docker build -t inventory-service:latest .
import_image_to_k3s "inventory-service:latest"
cd ..

# Déployer sur Kubernetes
echo "Déploiement du Service de Produits sur Kubernetes..."
kubectl apply -f k8s/product-service.yaml

echo "Attente que le Service de Produits soit prêt..."
kubectl wait --for=condition=available --timeout=300s deployment/product-service

echo "Déploiement du Service d'Inventaire sur Kubernetes..."
kubectl apply -f k8s/inventory-service.yaml

echo "Attente que le Service d'Inventaire soit prêt..."
kubectl wait --for=condition=available --timeout=300s deployment/inventory-service

# Afficher le statut
echo "Vérification du statut des déploiements..."
kubectl get deployments
kubectl get services
kubectl get pods

echo "Déploiement terminé avec succès."
echo "Système de Gestion de Boutique opérationnel"
echo "Utilisez './test.sh' pour tester l'application."
