#!/bin/bash

# Script de contrôle Redis pour Tshiakani VTC
# Usage: ./redis-control.sh [start|stop|restart|status|test]

set -e

REDIS_PATH="/opt/homebrew/bin"
REDIS_CLI="$REDIS_PATH/redis-cli"
BREW_PATH="/opt/homebrew/bin/brew"

# Fonction pour démarrer Redis
start_redis() {
    echo "🔄 Démarrage de Redis..."
    $BREW_PATH services start redis
    sleep 2
    
    if $REDIS_CLI ping &> /dev/null; then
        echo "✅ Redis démarré avec succès"
        echo "   Port: 6379"
        echo "   Host: localhost"
    else
        echo "❌ Erreur: Redis n'a pas pu démarrer"
        exit 1
    fi
}

# Fonction pour arrêter Redis
stop_redis() {
    echo "🛑 Arrêt de Redis..."
    $BREW_PATH services stop redis
    echo "✅ Redis arrêté"
}

# Fonction pour redémarrer Redis
restart_redis() {
    echo "🔄 Redémarrage de Redis..."
    stop_redis
    sleep 2
    start_redis
}

# Fonction pour vérifier le statut de Redis
status_redis() {
    echo "📊 Statut de Redis:"
    echo ""
    
    # Vérifier si Redis est en cours d'exécution
    if $REDIS_CLI ping &> /dev/null; then
        echo "✅ Redis est en cours d'exécution"
        echo ""
        
        # Afficher les informations du serveur
        echo "📡 Informations du serveur:"
        $REDIS_CLI INFO server | grep -E "redis_version|redis_mode|os|arch_bits|process_id|tcp_port" | sed 's/^/   /'
        echo ""
        
        # Afficher les statistiques
        echo "📊 Statistiques:"
        $REDIS_CLI INFO stats | grep -E "total_connections_received|total_commands_processed|instantaneous_ops_per_sec|total_keys|expired_keys" | sed 's/^/   /'
        echo ""
        
        # Afficher la mémoire
        echo "💾 Mémoire:"
        $REDIS_CLI INFO memory | grep -E "used_memory_human|used_memory_peak_human|used_memory_rss_human|maxmemory_human" | sed 's/^/   /'
        echo ""
        
        # Afficher les clients
        echo "👥 Clients:"
        $REDIS_CLI INFO clients | grep -E "connected_clients|blocked_clients" | sed 's/^/   /'
        echo ""
        
        # Afficher le nombre de clés
        echo "🔑 Clés:"
        DBSIZE=$($REDIS_CLI DBSIZE)
        echo "   Nombre de clés: $DBSIZE"
        echo ""
        
        # Afficher les clés OTP
        OTP_KEYS=$($REDIS_CLI KEYS "otp:*" | wc -l | tr -d ' ')
        echo "   Codes OTP: $OTP_KEYS"
        
        # Afficher les inscriptions en attente
        REGISTER_KEYS=$($REDIS_CLI KEYS "pending:register:*" | wc -l | tr -d ' ')
        echo "   Inscriptions en attente: $REGISTER_KEYS"
        
        # Afficher les connexions en attente
        LOGIN_KEYS=$($REDIS_CLI KEYS "pending:login:*" | wc -l | tr -d ' ')
        echo "   Connexions en attente: $LOGIN_KEYS"
        
        # Afficher le rate limiting
        RATE_KEYS=$($REDIS_CLI KEYS "otp:rate:*" | wc -l | tr -d ' ')
        echo "   Rate limiting: $RATE_KEYS"
        
        # Afficher les positions des conducteurs
        DRIVER_KEYS=$($REDIS_CLI KEYS "driver:*" | wc -l | tr -d ' ')
        echo "   Positions des conducteurs: $DRIVER_KEYS"
        
    else
        echo "❌ Redis n'est pas en cours d'exécution"
        echo ""
        echo "💡 Pour démarrer Redis:"
        echo "   ./redis-control.sh start"
        echo "   ou"
        echo "   brew services start redis"
    fi
}

# Fonction pour tester Redis
test_redis() {
    echo "🧪 Test de connexion Redis..."
    echo ""
    
    if $REDIS_CLI ping &> /dev/null; then
        echo "✅ Redis est accessible"
        echo ""
        
        # Tester la connexion depuis Node.js
        echo "🧪 Test de connexion depuis Node.js..."
        cd "$(dirname "$0")"
        node test-redis-connection.js
    else
        echo "❌ Redis n'est pas accessible"
        echo ""
        echo "💡 Pour démarrer Redis:"
        echo "   ./redis-control.sh start"
        echo "   ou"
        echo "   brew services start redis"
        exit 1
    fi
}

# Fonction pour afficher l'aide
show_help() {
    echo "📖 Script de contrôle Redis pour Tshiakani VTC"
    echo ""
    echo "Usage: ./redis-control.sh [command]"
    echo ""
    echo "Commands:"
    echo "  start     - Démarrer Redis"
    echo "  stop      - Arrêter Redis"
    echo "  restart   - Redémarrer Redis"
    echo "  status    - Afficher le statut de Redis"
    echo "  test      - Tester la connexion Redis"
    echo "  help      - Afficher cette aide"
    echo ""
    echo "Exemples:"
    echo "  ./redis-control.sh start"
    echo "  ./redis-control.sh status"
    echo "  ./redis-control.sh test"
    echo ""
}

# Gestion des arguments
case "$1" in
    start)
        start_redis
        ;;
    stop)
        stop_redis
        ;;
    restart)
        restart_redis
        ;;
    status)
        status_redis
        ;;
    test)
        test_redis
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        if [ -z "$1" ]; then
            status_redis
        else
            echo "❌ Commande inconnue: $1"
            echo ""
            show_help
            exit 1
        fi
        ;;
esac

