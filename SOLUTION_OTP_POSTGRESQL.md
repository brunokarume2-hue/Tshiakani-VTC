# 🔧 Solution Alternative : Stockage OTP dans PostgreSQL

## 📋 Date : 2025-01-15

---

## ⚠️ Problème Actuel

Redis n'est pas accessible depuis Cloud Run malgré le VPC connector configuré.  
Le fallback Map en mémoire ne fonctionne pas car Cloud Run utilise plusieurs instances, et chaque instance a son propre Map.

---

## ✅ Solution : Utiliser PostgreSQL pour les OTP

PostgreSQL est déjà configuré et accessible depuis Cloud Run.  
Nous pouvons créer une table temporaire pour stocker les codes OTP.

### Avantages

- ✅ **Déjà configuré** : PostgreSQL est accessible
- ✅ **Partagé entre instances** : Toutes les instances Cloud Run accèdent à la même base
- ✅ **Fiable** : Pas de problème de connexion réseau
- ✅ **Expiration automatique** : Via une colonne `expires_at` et un job de nettoyage

### Inconvénients

- ⚠️ **Plus lent** : PostgreSQL est plus lent que Redis (mais acceptable pour les OTP)
- ⚠️ **Table supplémentaire** : Nécessite une table `otp_codes`

---

## 🔧 Implémentation

### 1. Créer la table OTP

```sql
CREATE TABLE IF NOT EXISTS otp_codes (
    id SERIAL PRIMARY KEY,
    phone_number VARCHAR(20) NOT NULL,
    code VARCHAR(6) NOT NULL,
    attempts INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),
    expires_at TIMESTAMP NOT NULL,
    UNIQUE(phone_number)
);

CREATE INDEX idx_otp_phone ON otp_codes(phone_number);
CREATE INDEX idx_otp_expires ON otp_codes(expires_at);
```

### 2. Modifier OTPService.js

Remplacer le stockage Redis par PostgreSQL pour les OTP.

### 3. Job de nettoyage

Créer un job qui supprime les codes expirés toutes les 5 minutes.

---

## 🚀 Alternative Rapide : Utiliser le Map mais avec une seule instance Cloud Run

Si vous préférez garder Redis, vous pouvez :

1. **Limiter Cloud Run à 1 instance** :
```bash
gcloud run services update tshiakani-vtc-backend \
  --region=us-central1 \
  --project=tshiakani-vtc-477711 \
  --min-instances=1 \
  --max-instances=1
```

2. **Vérifier que Redis se connecte** en regardant les logs

---

## 📝 Recommandation

**Pour la production** : Utiliser PostgreSQL pour les OTP (plus fiable)  
**Pour les tests** : Limiter à 1 instance Cloud Run pour utiliser le Map

---

**Date** : 2025-01-15

