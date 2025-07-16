const express = require('express');
const app = express();
const PORT = process.env.PORT || 5000;

// Middleware pour parser le JSON
app.use(express.json());

// Données simulées des produits
const products = [
  { id: 1, name: "Smartphone Galaxy", price: 699.99, category: "Electronics", stock: 25 },
  { id: 2, name: "Laptop ThinkPad", price: 1299.99, category: "Electronics", stock: 15 },
  { id: 3, name: "Chaise de Bureau", price: 159.99, category: "Furniture", stock: 8 },
  { id: 4, name: "Casque Bluetooth", price: 89.99, category: "Electronics", stock: 32 }
];

// Endpoint principal pour récupérer les produits
app.get('/products', (req, res) => {
  res.json({ 
    message: "Catalogue de produits disponibles",
    products: products,
    totalProducts: products.length,
    timestamp: new Date().toISOString(),
    service: "product-service"
  });
});

// Endpoint pour récupérer un produit spécifique
app.get('/products/:id', (req, res) => {
  const productId = parseInt(req.params.id);
  const product = products.find(p => p.id === productId);
  
  if (product) {
    res.json({
      message: "Produit trouvé",
      product: product,
      timestamp: new Date().toISOString(),
      service: "product-service"
    });
  } else {
    res.status(404).json({
      error: "Produit non trouvé",
      productId: productId,
      timestamp: new Date().toISOString(),
      service: "product-service"
    });
  }
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: "HEALTHY",
    service: "product-service",
    uptime: process.uptime(),
    productsCount: products.length,
    timestamp: new Date().toISOString()
  });
});

// Démarrage du serveur
app.listen(PORT, () => {
  console.log(`Service de Produits démarré sur le port ${PORT}`);
  console.log(`${products.length} produits disponibles dans le catalogue`);
});
