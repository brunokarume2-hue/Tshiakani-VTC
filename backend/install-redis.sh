#!/bin/bash

# Script d'installation et de configuration Redis pour Tshiakani VTC
# Compatible macOS et Linux

set -e

echo "🚀 Installation et configuration Redis pour Tshiakani VTC"
echo "=========================================================="
echo ""

# Fonction pour détecter l'OS
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macOS"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "Linux"
    else
        echo "Unknown"
    fi
}

OS=$(detect_os)
echo "📱 OS détecté: $OS"
echo ""

# Vérifier si Redis est déjà installé
if command -v redis-cli &> /dev/null; then
    echo "✅ Redis est déjà installé"
    redis-cli --version
else
    echo "❌ Redis n'est pas installé"
    echo ""
    
    if [ "$OS" == "macOS" ]; then
        echo "📦 Installation de Redis sur macOS..."
        
        # Vérifier si Homebrew est installé
        if command -v brew &> /dev/null; then
            echo "✅ Homebrew est installé"
            echo "📦 Installation de Redis avec Homebrew..."
            brew install redis
            echo "✅ Redis installé avec succès"
        else
            echo "❌ Homebrew n'est pas installé"
            echo ""
            echo "📥 Installation de Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            
            echo "📦 Installation de Redis avec Homebrew..."
            brew install redis
            echo "✅ Redis installé avec succès"
        fi
    elif [ "$OS" == "Linux" ]; then
        echo "📦 Installation de Redis sur Linux..."
        
        if command -v apt-get &> /dev/null; then
            # Ubuntu/Debian
            sudo apt-get update
            sudo apt-get install -y redis-server
        elif command -v yum &> /dev/null; then
            # CentOS/RHEL
            sudo yum install -y redis
        elif command -v dnf &> /dev/null; then
            # Fedora
            sudo dnf install -y redis
        else
            echo "❌ Gestionnaire de paquets non supporté"
            exit 1
        fi
        
        echo "✅ Redis installé avec succès"
    else
        echo "❌ OS non supporté: $OS"
        echo "Veuillez installer Redis manuellement"
        exit 1
    fi
fi

echo ""
echo "🔄 Démarrage de Redis..."

if [ "$OS" == "macOS" ]; then
    # macOS avec Homebrew
    brew services start redis
elif [ "$OS" == "Linux" ]; then
    # Linux
    sudo systemctl start redis-server
    sudo systemctl enable redis-server
fi

# Attendre que Redis démarre
sleep 2

# Vérifier que Redis fonctionne
echo "🔍 Vérification de la connexion Redis..."
if redis-cli ping &> /dev/null; then
    echo "✅ Redis est en cours d'exécution"
    redis-cli ping
else
    echo "❌ Erreur: Redis n'est pas accessible"
    echo "Veuillez vérifier que Redis est démarré"
    exit 1
fi

echo ""
echo "⚙️  Configuration des variables d'environnement..."

# Aller dans le dossier backend
cd "$(dirname "$0")"

# Vérifier si .env existe
if [ ! -f .env ]; then
    echo "📄 Création du fichier .env à partir de ENV.example..."
    cp ENV.example .env
fi

# Vérifier si les variables Redis sont déjà dans .env
if grep -q "REDIS_HOST" .env; then
    echo "✅ Variables Redis déjà configurées dans .env"
else
    echo "➕ Ajout des variables Redis dans .env..."
    
    # Ajouter les variables Redis à la fin du fichier .env
    cat >> .env << 'EOF'

# ===========================================
# Redis (Memorystore)
# ===========================================
# Host Redis (localhost pour développement, adresse IP pour production)
REDIS_HOST=localhost

# Port Redis (6379 par défaut)
REDIS_PORT=6379

# Mot de passe Redis (optionnel, laisser vide si pas de mot de passe)
REDIS_PASSWORD=

# Timeout de connexion (millisecondes)
REDIS_CONNECT_TIMEOUT=10000
EOF
    
    echo "✅ Variables Redis ajoutées dans .env"
fi

echo ""
echo "🧪 Test de connexion Redis depuis Node.js..."

# Créer un script de test temporaire
cat > test-redis-connection.js << 'EOF'
require('dotenv').config();
const { getRedisService } = require('./services/RedisService');

async function testRedis() {
  try {
    console.log('📡 Configuration Redis:');
    console.log('   REDIS_HOST:', process.env.REDIS_HOST || 'localhost');
    console.log('   REDIS_PORT:', process.env.REDIS_PORT || 6379);
    console.log('');
    
    const redisService = getRedisService();
    console.log('🔄 Connexion à Redis...');
    
    await redisService.connect();
    console.log('✅ Redis connecté avec succès');
    
    const isReady = redisService.isReady();
    console.log('✅ Redis est prêt:', isReady);
    
    const testResult = await redisService.testConnection();
    console.log('✅ Test de connexion Redis:', testResult ? 'OK' : 'ÉCHEC');
    
    if (testResult) {
      console.log('');
      console.log('🎉 Redis est configuré et fonctionne correctement !');
    }
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Erreur de connexion Redis:', error.message);
    console.error('');
    console.error('💡 Vérifiez que:');
    console.error('   1. Redis est en cours d\'exécution (redis-cli ping)');
    console.error('   2. Les variables d\'environnement sont correctes dans .env');
    console.error('   3. Le port Redis n\'est pas bloqué par un firewall');
    process.exit(1);
  }
}

testRedis();
EOF

# Exécuter le test
if node test-redis-connection.js; then
    echo ""
    echo "✅ Test réussi ! Redis est configuré et fonctionne."
    rm -f test-redis-connection.js
else
    echo ""
    echo "❌ Test échoué. Vérifiez les erreurs ci-dessus."
    rm -f test-redis-connection.js
    exit 1
fi

echo ""
echo "=========================================================="
echo "✅ Installation et configuration Redis terminées !"
echo ""
echo "📝 Prochaines étapes:"
echo "   1. Vérifiez les variables Redis dans backend/.env"
echo "   2. Démarrez le serveur backend: npm run dev"
echo "   3. Vérifiez les logs pour confirmer la connexion Redis"
echo ""
echo "🔍 Commandes utiles:"
echo "   redis-cli ping          # Vérifier que Redis fonctionne"
echo "   redis-cli KEYS 'otp:*'  # Voir les codes OTP stockés"
echo "   brew services stop redis # Arrêter Redis (macOS)"
echo "   brew services start redis # Démarrer Redis (macOS)"
echo ""

