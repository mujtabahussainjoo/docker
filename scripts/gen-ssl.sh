#!/usr/bin/env bash
set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SSL_DIR="$ROOT_DIR/nginx/ssl"
mkdir -p "$SSL_DIR"

for DOMAIN in mydemo1.local mydemo2.local; do
  echo "Generating SSL for $DOMAIN..."
  openssl req -x509 -nodes -days 825 -newkey rsa:2048 \
    -keyout "$SSL_DIR/$DOMAIN.key" \
    -out    "$SSL_DIR/$DOMAIN.crt" \
    -subj   "/C=IN/ST=WB/L=Kolkata/O=Dev/CN=$DOMAIN" \
    -addext "subjectAltName=DNS:$DOMAIN"
  echo "Done: $SSL_DIR/$DOMAIN.crt"
done