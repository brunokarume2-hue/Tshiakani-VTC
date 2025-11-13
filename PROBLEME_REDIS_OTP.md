# ⚠️ Problème : Vérification OTP ne fonctionne pas

## 📋 Date : 2025-01-15

---

## 🔍 Diagnostic

### Problème Identifié

La vérification d'OTP échoue avec l'erreur :
```json
{
    "error": "Erreur lors de la vérification du code",
    "success": false
}
```

### Causes Probables

1. **Redis n'est pas connecté** : Le health check montre `"redis": {"status": "not_configured"}`
2. **Cloud Run utilise plusieurs instances** : Chaque instance a son propre Map en mémoire
3. **Le code OTP est stocké dans l'instance A mais vérifié dans l'instance B**
4. **Memorystore Redis nécessite un VPC connector** pour être accessible depuis Cloud Run

---

## 🔧 Solutions

### Solution 1 : Configurer le VPC Connector (RECOMMANDÉ)

Memorystore Redis nécessite une connexion via VPC. Cloud Run doit avoir un VPC connector configuré.

**Étapes :**

1. **Créer un VPC connector** (si pas déjà fait) :
```bash
gcloud compute networks vpc-access connectors create tshiakani-vpc-connector \
  --region=us-central1 \
  --subnet-project=tshiakani-vtc-477711 \
  --subnet=default \
  --min-instances=2 \
  --max-instances=3 \
  --machine-type=e2-micro
```

2. **Configurer Cloud Run pour utiliser le VPC connector** :
```bash
gcloud run services update tshiakani-vtc-backend \
  --region=us-central1 \
  --project=tshiakani-vtc-477711 \
  --vpc-connector=tshiakani-vpc-connector \
  --vpc-egress=all-traffic
```

3. **Vérifier que Redis est accessible** :
```bash
curl https://tshiakani-vtc-backend-418102154417.us-central1.run.app/health
```

### Solution 2 : Utiliser PostgreSQL pour stocker les OTP (Temporaire)

Si Redis n'est pas disponible, on peut stocker les OTP dans PostgreSQL avec une table temporaire.

**Avantages :**
- Fonctionne immédiatement (PostgreSQL est déjà configuré)
- Partage les données entre toutes les instances Cloud Run

**Inconvénients :**
- Plus lent que Redis
- Nécessite une table supplémentaire

---

## 📝 État Actuel

- ✅ **Envoi d'OTP** : Fonctionne (via Twilio)
- ❌ **Vérification d'OTP** : Échoue (Redis non connecté)
- ⚠️ **Redis** : Configuré mais non connecté (VPC connector manquant)

---

## 🚀 Prochaines Étapes

1. **Configurer le VPC connector** pour Cloud Run
2. **Vérifier la connexion Redis** via le health check
3. **Tester la vérification d'OTP** après configuration

---

**Date** : 2025-01-15

