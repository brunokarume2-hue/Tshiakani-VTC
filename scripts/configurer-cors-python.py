#!/usr/bin/env python3
"""
Script Python pour configurer CORS dans Cloud Run
Parse correctement les variables d'environnement et ajoute CORS_ORIGIN
"""

import subprocess
import json
import sys

# Configuration
GCP_PROJECT_ID = "tshiakani-vtc-477711"
SERVICE_NAME = "tshiakani-vtc-backend"
REGION = "us-central1"
CORS_ORIGINS = "https://tshiakani-vtc-99cea.web.app,https://tshiakani-vtc-99cea.firebaseapp.com,capacitor://localhost,ionic://localhost,http://localhost:3001,http://localhost:5173"

def get_current_env_vars():
    """Récupère les variables d'environnement actuelles"""
    try:
        cmd = [
            "gcloud", "run", "services", "describe", SERVICE_NAME,
            "--region", REGION,
            "--project", GCP_PROJECT_ID,
            "--format", "json"
        ]
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        service_data = json.loads(result.stdout)
        
        env_vars = {}
        for env in service_data.get("spec", {}).get("template", {}).get("spec", {}).get("containers", [{}])[0].get("env", []):
            name = env.get("name")
            value = env.get("value", "")
            if name:
                env_vars[name] = value
        
        return env_vars
    except Exception as e:
        print(f"❌ Erreur lors de la récupération des variables: {e}")
        return {}

def update_cors():
    """Met à jour CORS_ORIGIN dans Cloud Run"""
    print("🔧 Configuration CORS...")
    print("")
    
    # Récupérer les variables existantes
    print("📋 Récupération des variables d'environnement actuelles...")
    env_vars = get_current_env_vars()
    
    if not env_vars:
        print("⚠️  Impossible de récupérer les variables existantes")
        print("Utilisation des variables par défaut...")
        env_vars = {
            "NODE_ENV": "production",
            "INSTANCE_CONNECTION_NAME": "tshiakani-vtc-477711:us-central1:tshiakani-vtc-db",
            "DB_USER": "postgres",
            "DB_PASSWORD": "H38TYjMcJfTudmFmSVzvWZk45",
            "DB_NAME": "TshiakaniVTC",
            "DB_HOST": "/cloudsql/tshiakani-vtc-477711:us-central1:tshiakani-vtc-db",
            "REDIS_HOST": "10.184.176.123",
            "REDIS_PORT": "6379",
            "GOOGLE_MAPS_API_KEY": "AIzaSyBBSOYw1qSUrp3yU4t097tjRZRwRZ0z1w8",
            "FIREBASE_PROJECT_ID": "tshiakani-vtc-477711-306f0"
        }
    
    # Ajouter/modifier CORS_ORIGIN
    env_vars["CORS_ORIGIN"] = CORS_ORIGINS
    
    print(f"✅ {len(env_vars)} variables d'environnement à configurer")
    print("")
    
    # Construire la chaîne de variables
    env_string = ",".join([f"{k}={v}" for k, v in env_vars.items()])
    
    print("🚀 Déploiement de la nouvelle révision...")
    print("")
    
    # Exécuter la commande gcloud
    cmd = [
        "gcloud", "run", "services", "update", SERVICE_NAME,
        "--set-env-vars", env_string,
        "--region", REGION,
        "--project", GCP_PROJECT_ID,
        "--quiet"
    ]
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        print("✅ CORS configuré avec succès !")
        print("")
        print("📋 Variables configurées :")
        for key in sorted(env_vars.keys()):
            if key == "CORS_ORIGIN":
                print(f"  ✅ {key} = {env_vars[key][:50]}...")
            else:
                print(f"  ✅ {key}")
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ Erreur lors du déploiement: {e}")
        print("")
        print("📝 Commande qui a échoué :")
        print(" ".join(cmd))
        print("")
        print("⚠️  Utilisez la Console GCP à la place :")
        print(f"https://console.cloud.google.com/run/detail/{REGION}/{SERVICE_NAME}?project={GCP_PROJECT_ID}")
        return False

if __name__ == "__main__":
    success = update_cors()
    sys.exit(0 if success else 1)

