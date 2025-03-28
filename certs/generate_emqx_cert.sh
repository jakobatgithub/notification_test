#!/bin/bash

# Go to certs directory
cd "$(dirname "$0")"

openssl req -x509 -nodes -days 365 \
  -newkey rsa:2048 \
  -keyout emqx.key \
  -out emqx.crt \
  -config openssl.cnf

echo "✅ Certificate generated: emqx.crt"
