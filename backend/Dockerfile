# Dockerfile pour Tshiakani VTC Backend
FROM node:20-alpine

# Installer les dépendances système nécessaires pour PostgreSQL
RUN apk add --no-cache \
    python3 \
    make \
    g++ \
    postgresql-client

# Créer le répertoire de travail
WORKDIR /app

# Copier les fichiers de configuration
COPY package*.json ./

# Installer les dépendances
RUN npm ci --only=production

# Copier le code source
COPY . .

# Créer le répertoire pour les logs
RUN mkdir -p logs

# Exposer le port (Cloud Run utilise 8080)
EXPOSE 8080

# Variables d'environnement par défaut
ENV NODE_ENV=production
ENV PORT=8080

# Démarrer l'application
CMD ["node", "server.postgres.js"]
