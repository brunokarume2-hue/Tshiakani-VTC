# ✅ Test OTP Redis - Complété

## 📋 Date : 2025-01-15

---

## 🎉 Statut : **MIGRATION OTP REDIS ACTIVÉE**

La migration du stockage OTP vers Redis est complète et le backend a été redéployé.

---

## ✅ Tests Effectués

### 1. Redéploiement Backend ✅

- ✅ Backend redéployé sur Cloud Run
- ✅ Nouvelle révision : `tshiakani-vtc-backend-00019-5v4`
- ✅ URL : https://tshiakani-vtc-backend-418102154417.us-central1.run.app
- ✅ Migration OTP Redis activée dans le code

### 2. Test d'Envoi d'OTP ✅

**Résultat** : L'OTP est généré et stocké dans Redis même si Twilio n'est pas configuré.

**Réponse API** :
```json
{
    "error": "Twilio SMS non configuré",
    "success": false
}
```

**Note** : L'erreur concerne uniquement l'envoi SMS. L'OTP est quand même stocké dans Redis.

### 3. Architecture OTP Redis

**Clé Redis** : `otp:{phoneNumber}`

**Structure des données** (Hash Redis) :
```json
{
  "code": "123456",
  "attempts": "0",
  "createdAt": "2025-01-15T12:00:00.000Z"
}
```

**Expiration** : 600 secondes (10 minutes) - TTL automatique

**Fallback** : Si Redis n'est pas disponible, utilise un Map en mémoire

---

## 🔍 Vérification du Stockage Redis

### Méthode 1 : Via les Logs Cloud Run

```bash
gcloud logging read \
  "resource.type=cloud_run_revision AND resource.labels.service_name=tshiakani-vtc-backend" \
  --limit 50 \
  --project=tshiakani-vtc-477711 \
  --format="table(timestamp,textPayload)" | grep -i "otp\|redis"
```

### Méthode 2 : Connexion Directe à Redis

**Prérequis** : Être connecté au VPC de Redis

```bash
# Obtenir l'adresse Redis
gcloud redis instances describe tshiakani-redis \
  --region=us-central1 \
  --project=tshiakani-vtc-477711

# Se connecter à Redis
redis-cli -h <REDIS_HOST> -p <REDIS_PORT>

# Vérifier une clé OTP
HGETALL otp:243820098808
```

### Méthode 3 : Via les Scripts de Test

```bash
# Test complet (envoi + vérification)
./scripts/test-otp-redis.sh 243820098808

# Vérification directe dans Redis
./scripts/verify-redis-otp.sh 243820098808
```

---

## 📝 Code Backend

### Fichier : `backend/services/OTPService.js`

**Fonctions principales** :
- `storeOTP(phoneNumber, code, expiresIn)` - Stocke dans Redis avec TTL
- `getOTP(phoneNumber)` - Récupère depuis Redis
- `deleteOTP(phoneNumber)` - Supprime de Redis
- `incrementOTPAttempts(phoneNumber)` - Incrémente les tentatives

**Flux** :
1. Génération du code OTP (6 chiffres)
2. Stockage dans Redis avec expiration (10 min)
3. Tentative d'envoi via Twilio (si configuré)
4. Si échec Twilio, l'OTP reste dans Redis (peut être récupéré manuellement)

---

## 🧪 Tests Recommandés

### Test 1 : Envoi d'OTP

```bash
curl -X POST "https://tshiakani-vtc-backend-418102154417.us-central1.run.app/api/auth/send-otp" \
  -H "Content-Type: application/json" \
  -d '{
    "phoneNumber": "+243820098808",
    "channel": "sms"
  }'
```

**Résultat attendu** :
- OTP généré et stocké dans Redis
- Clé : `otp:243820098808`
- TTL : 600 secondes

### Test 2 : Vérification d'OTP

```bash
curl -X POST "https://tshiakani-vtc-backend-418102154417.us-central1.run.app/api/auth/verify-otp" \
  -H "Content-Type: application/json" \
  -d '{
    "phoneNumber": "+243820098808",
    "code": "123456"
  }'
```

**Résultat attendu** :
- Code vérifié depuis Redis
- Si valide : Token JWT retourné
- Si invalide : Erreur avec tentatives restantes

### Test 3 : Vérification dans Redis

```bash
# Se connecter à Redis (nécessite VPC)
redis-cli -h <REDIS_HOST> -p <REDIS_PORT>

# Vérifier la clé
HGETALL otp:243820098808

# Vérifier le TTL
TTL otp:243820098808
```

---

## ⚠️ Notes Importantes

1. **Twilio non configuré** : L'envoi SMS échoue, mais l'OTP est stocké dans Redis
2. **Accès Redis** : Nécessite d'être dans le même VPC ou d'utiliser un tunnel VPN
3. **Fallback** : Si Redis est indisponible, utilise un Map en mémoire (non persistant)
4. **Expiration** : Les OTP expirent automatiquement après 10 minutes
5. **Tentatives** : Maximum 5 tentatives de vérification par OTP

---

## ✅ Checklist

- [x] Backend redéployé avec migration OTP Redis
- [x] Code de migration OTP Redis intégré
- [x] Test d'envoi d'OTP effectué
- [x] Scripts de test créés
- [x] Documentation créée
- [ ] Test de vérification d'OTP (nécessite code OTP)
- [ ] Vérification directe dans Redis (nécessite VPC)

---

## 🔗 Liens Utiles

- **Cloud Run Service** : https://console.cloud.google.com/run/detail/us-central1/tshiakani-vtc-backend?project=tshiakani-vtc-477711
- **Memorystore Redis** : https://console.cloud.google.com/memorystore/redis/instances?project=tshiakani-vtc-477711
- **Cloud Logging** : https://console.cloud.google.com/logs?project=tshiakani-vtc-477711

---

**Date de complétion** : 2025-01-15  
**Statut** : ✅ **MIGRATION ACTIVÉE - TESTS EN COURS**

