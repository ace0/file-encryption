#!/bin/sh
# perform yubikey challenge-response using openssl dgst
# sudo ykchalresp -2 "$1"

echo -n "$1" | openssl dgst -sha1 -mac HMAC -macopt hexkey:$2 -binary | xxd -p