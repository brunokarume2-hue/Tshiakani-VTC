# ⚡ Instructions Rapides - Erreur Info.plist

## 🎯 Erreur Actuelle

```
Multiple commands produce '.../Info.plist'
```

## ✅ Solution Rapide (2 minutes)

### Dans Xcode :

1. **Target "Tshiakani VTC"** → **Build Phases**
2. **Développez "Copy Bundle Resources"**
3. **Si Info.plist est présent** → **Sélectionnez-le** → **Bouton "-"**
4. **Product** > **Clean Build Folder** (⇧⌘K)
5. **Product** > **Build** (⌘B)

✅ **C'est tout !** L'erreur devrait disparaître.

---

**Guide détaillé** : `RESOLUTION_DUPLICATION_INFOPLIST.md`

