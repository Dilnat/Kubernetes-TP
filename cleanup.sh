#!/bin/bash

echo "Nettoyage du Système de Gestion de Boutique..."

# Supprimer les ressources déployées
echo "Suppression des services de la boutique..."
kubectl delete -f kubernetes/inventory-service.yaml || echo "Service d'inventaire déjà supprimé"
kubectl delete -f kubernetes/product-service.yaml || echo "Service de produits déjà supprimé"

# Vérifier l'état
echo "Vérification de l'état du cluster..."
kubectl get all

echo "Nettoyage terminé."
echo "Pour désinstaller complètement k3s, utilisez: sudo /usr/local/bin/k3s-uninstall.sh"
