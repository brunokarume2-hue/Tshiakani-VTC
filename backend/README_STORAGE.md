# 📦 Guide Cloud Storage - Tshiakani VTC

Guide complet pour configurer et utiliser Google Cloud Storage pour le stockage de fichiers.

## 🎯 Vue d'ensemble

Cloud Storage est utilisé pour stocker les documents des conducteurs:
- Permis de conduire
- Cartes grises
- Assurances
- Documents d'identité
- Photos de véhicules

## 📋 Configuration

### 1. Variables d'environnement

Ajoutez ces variables dans votre fichier `.env`:

```env
# Google Cloud Platform
GCP_PROJECT_ID=tshiakani-vtc
GOOGLE_CLOUD_PROJECT=tshiakani-vtc

# Cloud Storage
GCS_BUCKET_NAME=tshiakani-vtc-documents

# Credentials (développement local uniquement)
GOOGLE_APPLICATION_CREDENTIALS=./config/gcp-service-account.json
```

### 2. Créer le bucket Cloud Storage

```bash
# Option 1: Utiliser le script automatique
cd backend
chmod +x scripts/setup-cloud-storage.sh
./scripts/setup-cloud-storage.sh

# Option 2: Manuellement
gsutil mb -p tshiakani-vtc -l us-central1 -c STANDARD gs://tshiakani-vtc-documents
gsutil cors set backend/config/cors-storage.json gs://tshiakani-vtc-documents
gsutil versioning set on gs://tshiakani-vtc-documents
```

### 3. Vérifier la configuration

```bash
cd backend
npm run verify:storage
```

## 🚀 Utilisation

### Upload d'un document

```bash
curl -X POST http://localhost:3000/api/documents/upload \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "file=@permis.pdf" \
  -F "documentType=permis" \
  -F "folder=permis"
```

### Récupérer les documents d'un utilisateur

```bash
curl -X GET http://localhost:3000/api/documents/123 \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Obtenir une URL signée

```bash
curl -X GET http://localhost:3000/api/documents/url/permis/123/1234567890-permis.pdf \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Supprimer un document

```bash
curl -X DELETE http://localhost:3000/api/documents/permis/123/1234567890-permis.pdf \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## 📝 Types de documents supportés

- `permis` - Permis de conduire
- `carte-grise` - Carte grise du véhicule
- `assurance` - Assurance du véhicule
- `vehicle` - Photos du véhicule
- `identity` - Documents d'identité

## 🔒 Sécurité

- Les fichiers sont **privés par défaut**
- Accès via **URLs signées** (valides 1 an)
- Validation des types de fichiers (PDF, JPG, PNG, WEBP)
- Limite de taille: **10MB maximum**
- Authentification requise pour tous les endpoints

## 🐛 Dépannage

### Erreur: "Cloud Storage n'est pas configuré"

1. Vérifiez que `GCP_PROJECT_ID` est défini
2. Vérifiez que `GCS_BUCKET_NAME` est défini
3. En développement local, configurez `GOOGLE_APPLICATION_CREDENTIALS`
4. En production, vérifiez que le service account a les permissions

### Erreur: "Bucket does not exist"

Créez le bucket avec:
```bash
gsutil mb -p tshiakani-vtc -l us-central1 gs://tshiakani-vtc-documents
```

### Erreur: "Permission denied"

Vérifiez les permissions IAM:
```bash
gsutil iam get gs://tshiakani-vtc-documents
```

## 📚 Ressources

- [Documentation Cloud Storage](https://cloud.google.com/storage/docs)
- [Node.js Client Library](https://cloud.google.com/nodejs/docs/reference/storage/latest)
- [Signed URLs](https://cloud.google.com/storage/docs/access-control/signing-urls-with-helpers)

---

**Date de création:** Novembre 2025  
**Version:** 1.0.0

