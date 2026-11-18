#!/bin/bash
set -ex

source .env

# Copiar el VirtualHost y poner el dominio en ServerName
cp ../conf/000-default.conf /etc/apache2/sites-available/000-default.conf
sed -i "s/PUT_YOUR_DOMAIN_HERE/$CERTIFICATE_DOMAIN/" /etc/apache2/sites-available/000-default.conf
systemctl reload apache2

# Instalar Certbot con snap
snap install core
snap refresh core
apt remove certbot -y
snap install --classic certbot
ln -fs /snap/bin/certbot /usr/bin/certbot

# Obtener el certificado y configurar Apache sin preguntas
certbot --apache \
  -m "$CERTIFICATE_EMAIL" \
  --agree-tos \
  --no-eff-email \
  -d "$CERTIFICATE_DOMAIN" \
  --non-interactive