#!/usr/bin/env bash
set -euo pipefail

########################################
# CONFIG À ADAPTER
########################################

# Domaine principal
DOMAIN="ihsenalaya.xyz"

# Email de contact pour Let's Encrypt (recommandé)
LE_EMAIL="ton.email@domaine.com"

# Mot de passe du fichier PFX (pour App Gateway / Key Vault / autre)
PFX_PASSWORD="UnMotDePasseTrèsFort!"

# Dossier où l'on placera le PFX final
OUTPUT_DIR="$HOME/certs-${DOMAIN}"

########################################
# CRED Azure DNS (Service Principal)
# => À mettre en variables d'env AVANT de lancer le script
# export AZURE_TENANT_ID="..."
# export AZURE_SUBSCRIPTION_ID="..."
# export AZURE_CLIENT_ID="..."
# export AZURE_CLIENT_SECRET="..."
########################################

# Vérification des variables d'env Azure
for var in AZURE_TENANT_ID AZURE_SUBSCRIPTION_ID AZURE_CLIENT_ID AZURE_CLIENT_SECRET; do
  if [ -z "${!var:-}" ]; then
    echo "ERREUR: la variable d'environnement $var n'est pas définie."
    echo "Merci de faire : export $var=\"...\" avant de lancer ce script."
    exit 1
  fi
done

# Vérification des outils nécessaires
for cmd in curl openssl; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "ERREUR: commande '$cmd' introuvable. Installe-la avant de continuer."
    exit 1
  fi
done

########################################
# Installation d'acme.sh si nécessaire
########################################

if ! command -v acme.sh >/dev/null 2>&1; then
  echo "acme.sh non trouvé, installation..."
  curl https://get.acme.sh | sh
  # Recharge le profil pour avoir la commande acme.sh dans le PATH
  if [ -f "$HOME/.bashrc" ]; then
    # shellcheck source=/dev/null
    source "$HOME/.bashrc"
  elif [ -f "$HOME/.profile" ]; then
    # shellcheck source=/dev/null
    source "$HOME/.profile"
  fi
fi

echo "Version acme.sh : $(acme.sh --version || true)"

########################################
# Enregistrement de compte Let's Encrypt
########################################

if [ -n "$LE_EMAIL" ]; then
  echo "Enregistrement / mise à jour du compte Let's Encrypt avec l'email $LE_EMAIL"
  acme.sh --register-account -m "$LE_EMAIL" || true
fi

########################################
# Émission du certificat wildcard avec DNS-01 Azure
########################################

echo "Émission du certificat pour : $DOMAIN et *.${DOMAIN}"

acme.sh --issue \
  --dns dns_azure \
  -d "$DOMAIN" \
  -d "*.${DOMAIN}" \
  --keylength 2048 \
  --server letsencrypt

CERT_DIR="$HOME/.acme.sh/${DOMAIN}"
FULLCHAIN="${CERT_DIR}/fullchain.cer"
KEYFILE="${CERT_DIR}/${DOMAIN}.key"

if [ ! -f "$FULLCHAIN" ] || [ ! -f "$KEYFILE" ]; then
  echo "ERREUR: fichiers de certificat non trouvés dans ${CERT_DIR}"
  exit 1
fi

echo "Certificat émis avec succès !"
echo " - Fullchain : $FULLCHAIN"
echo " - Clé privée : $KEYFILE"

########################################
# Génération du PFX
########################################

mkdir -p "$OUTPUT_DIR"

PFX_FILE="${OUTPUT_DIR}/${DOMAIN}.pfx"

echo "Génération du PFX : $PFX_FILE"

openssl pkcs12 -export \
  -inkey "$KEYFILE" \
  -in "$FULLCHAIN" \
  -out "$PFX_FILE" \
  -password pass:"$PFX_PASSWORD"

echo "PFX généré avec succès."

########################################
# Récapitulatif
########################################

echo "==============================================="
echo " Certificat Let's Encrypt généré pour :"
echo "   - ${DOMAIN}"
echo "   - *.${DOMAIN}"
echo
echo " Fichiers importants :"
echo "   - Clé privée  : $KEYFILE"
echo "   - Fullchain   : $FULLCHAIN"
echo "   - PFX (TLS)   : $PFX_FILE"
echo "   - Mot de passe PFX : $PFX_PASSWORD"
echo
echo " Tu peux maintenant importer le PFX où tu veux :"
echo "   - Azure Key Vault"
echo "   - Application Gateway"
echo "   - Nginx / Apache (conversion si besoin)"
echo "==============================================="
