#!/bin/bash

set -e

echo "Test du Système de Gestion de Boutique..."

# Vérifier si kubectl est disponible
if ! command -v kubectl &> /dev/null; then
    echo "Erreur: kubectl n'est pas installé ou n'est pas dans le PATH"
    exit 1
fi

# Vérifier que les services sont déployés
echo "Vérification du statut des services..."
kubectl get pods -l app=inventory-service
kubectl get pods -l app=product-service

# Fonction pour tester un endpoint
test_endpoint() {
    local service=$1
    local port=$2
    local endpoint=$3
    local description=$4
    
    echo "Test: $description"
    
    # Utiliser port-forward pour tester
    kubectl port-forward service/$service 8080:$port &
    PID=$!
    
    # Attendre que le port-forward soit prêt
    sleep 4
    
    # Faire le test
    if curl -f -s http://localhost:8080$endpoint > /tmp/test_result.json; then
        echo "OK - $description"
        echo "Réponse:"
        cat /tmp/test_result.json | jq . 2>/dev/null || cat /tmp/test_result.json
        echo ""
    else
        echo "ÉCHEC - $description"
    fi
    
    # Arrêter le port-forward
    kill $PID 2>/dev/null || true
    sleep 2
}

# Tests
echo "Démarrage des tests du système..."

# Test du Service de Produits
test_endpoint "product-service" "5000" "/products" "Service de Produits - Catalogue complet"
test_endpoint "product-service" "5000" "/products/1" "Service de Produits - Produit spécifique (ID: 1)"
test_endpoint "product-service" "5000" "/health" "Service de Produits - Health check"

# Test du Service d'Inventaire
test_endpoint "inventory-service" "4000" "/inventory" "Service d'Inventaire - Inventaire complet"
test_endpoint "inventory-service" "4000" "/inventory/2" "Service d'Inventaire - Stock produit (ID: 2)"
test_endpoint "inventory-service" "4000" "/health" "Service d'Inventaire - Health check"

# Test de charge sur l'inventaire
echo "Test de charge sur l'inventaire..."
kubectl port-forward service/inventory-service 8080:4000 &
PID=$!
sleep 4

echo "Envoi de 8 requêtes d'inventaire consécutives..."
for i in {1..8}; do
    curl -s http://localhost:8080/inventory > /dev/null && echo -n "OK " || echo -n "ERR "
done
echo ""

kill $PID 2>/dev/null || true

# Test de différents produits
echo "Test de consultation de différents produits..."
kubectl port-forward service/product-service 8080:5000 &
PID=$!
sleep 4

echo "Consultation des produits 1 à 4..."
for i in {1..4}; do
    curl -s http://localhost:8080/products/$i > /dev/null && echo -n "OK " || echo -n "ERR "
done
echo ""

kill $PID 2>/dev/null || true

echo "Tests terminés."
echo ""
echo "Pour accéder aux services depuis l'extérieur:"
echo "  Service d'Inventaire: kubectl port-forward service/inventory-service 4000:4000"
echo "  Service de Produits: kubectl port-forward service/product-service 5000:5000"
echo ""
echo "Endpoints disponibles:"
echo "  http://localhost:4000/inventory (inventaire complet)"
echo "  http://localhost:4000/inventory/{id} (stock d'un produit)"
echo "  http://localhost:5000/products (catalogue produits)"
echo "  http://localhost:5000/products/{id} (produit spécifique)"
