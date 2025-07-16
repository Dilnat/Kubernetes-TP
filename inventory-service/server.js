const express = require('express');
const axios = require('axios');
const app = express();
const PORT = process.env.PORT || 4000;

// URL du service de produits - utilise le service DNS Kubernetes
const PRODUCT_SERVICE_URL = process.env.PRODUCT_SERVICE_URL || 'http://product-service:5000';

// Middleware pour parser le JSON
app.use(express.json());

// Données simulées d'inventaire
const inventory = {
  warehouseId: "WH-001",
  location: "Entrepôt Principal - Paris",
  manager: "Marie Dubois",
  lastUpdated: new Date().toISOString()
};

// Endpoint principal - récupère l'inventaire complet
app.get('/inventory', async (req, res) => {
  try {
    console.log(`📦 Récupération du catalogue depuis: ${PRODUCT_SERVICE_URL}/products`);
    const response = await axios.get(`${PRODUCT_SERVICE_URL}/products`);
    
    // Enrichir les données avec des informations d'inventaire
    const enrichedProducts = response.data.products.map(product => ({
      ...product,
      warehouse: inventory.warehouseId,
      location: inventory.location,
      status: product.stock > 10 ? "En stock" : product.stock > 0 ? "Stock limité" : "Rupture"
    }));
    
    res.json({
      message: "Inventaire complet de la boutique",
      inventory: {
        ...inventory,
        products: enrichedProducts,
        totalProducts: enrichedProducts.length,
        totalValue: enrichedProducts.reduce((sum, p) => sum + (p.price * p.stock), 0)
      },
      productService: {
        status: "Connecté",
        data: response.data
      },
      timestamp: new Date().toISOString(),
      service: "inventory-service"
    });
  } catch (error) {
    console.error('Erreur lors de la récupération des produits:', error.message);
    res.status(500).json({
      error: "Impossible d'accéder au service de produits",
      warehouse: inventory.warehouseId,
      details: error.message,
      timestamp: new Date().toISOString(),
      service: "inventory-service"
    });
  }
});

// Endpoint pour vérifier le stock d'un produit spécifique
app.get('/inventory/:productId', async (req, res) => {
  const productId = req.params.productId;
  
  try {
    console.log(`🔍 Vérification du stock pour le produit ${productId}`);
    const response = await axios.get(`${PRODUCT_SERVICE_URL}/products/${productId}`);
    
    const product = response.data.product;
    const stockStatus = {
      productId: product.id,
      productName: product.name,
      currentStock: product.stock,
      warehouse: inventory.warehouseId,
      location: inventory.location,
      status: product.stock > 10 ? "En stock" : product.stock > 0 ? "Stock limité" : "Rupture",
      reorderLevel: 5,
      needsReorder: product.stock <= 5
    };
    
    res.json({
      message: "Informations de stock",
      inventory: stockStatus,
      timestamp: new Date().toISOString(),
      service: "inventory-service"
    });
  } catch (error) {
    res.status(404).json({
      error: "Produit non trouvé dans l'inventaire",
      productId: productId,
      warehouse: inventory.warehouseId,
      timestamp: new Date().toISOString(),
      service: "inventory-service"
    });
  }
});

// Health check endpoint
app.get('/health', async (req, res) => {
  try {
    // Vérifie si le service de produits est disponible
    const response = await axios.get(`${PRODUCT_SERVICE_URL}/health`, { timeout: 5000 });
    
    res.json({
      status: "HEALTHY",
      service: "inventory-service",
      warehouse: inventory.warehouseId,
      uptime: process.uptime(),
      productServiceStatus: response.data.status,
      dependencies: {
        productService: "CONNECTED"
      },
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(503).json({
      status: "DEGRADED",
      service: "inventory-service",
      warehouse: inventory.warehouseId,
      error: "Service de produits non disponible",
      dependencies: {
        productService: "DISCONNECTED"
      },
      timestamp: new Date().toISOString()
    });
  }
});

// Démarrage du serveur
app.listen(PORT, () => {
  console.log(`Service d'Inventaire démarré sur le port ${PORT}`);
  console.log(`Entrepôt: ${inventory.location}`);
  console.log(`Service de produits: ${PRODUCT_SERVICE_URL}`);
});
