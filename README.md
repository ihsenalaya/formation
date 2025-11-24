# formation
# Certificat wildcard Let’s Encrypt pour `*.ihsenalaya.xyz` (Azure DNS)

Ce `README.md` contient **un seul script Bash** qui :

- crée un certificat Let’s Encrypt pour :
  - `ihsenalaya.xyz`
  - `*.ihsenalaya.xyz`
- via **DNS-01** avec **Azure DNS** (grâce à `acme.sh`)
- génère un fichier **PFX** (prêt pour App Gateway, Key Vault, Nginx, etc.)

> Aucune config App Gateway / Key Vault dans ce script.  
> Il fait **uniquement** : _certificat + PFX_.

---

## 1. Prérequis

### Côté Azure

- Domaine : `ihsenalaya.xyz`
- Zone DNS publique `ihsenalaya.xyz` hébergée dans **Azure DNS**
- Un **Service Principal** avec un rôle du type :
  - `DNS Zone Contributor` sur la zone DNS `ihsenalaya.xyz`

Tu dois récupérer pour ce Service Principal :

- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`
- `AZURE_CLIENT_ID`
- `AZURE_CLIENT_SECRET`

### Côté machine/VM

- Linux (ou WSL) avec :
  - `bash`
  - `curl`
  - `openssl`
- Accès Internet
- Le script installera `acme.sh` si nécessaire

---

## 2. Variables d’environnement Azure DNS

Avant d’exécuter le script, **exporte** ces variables :

```bash
export AZURE_TENANT_ID="<ton-tenant-id>"
export AZURE_SUBSCRIPTION_ID="<ta-subscription-id>"
export AZURE_CLIENT_ID="<client-id-du-service-principal>"
export AZURE_CLIENT_SECRET="<secret-du-service-principal>"
