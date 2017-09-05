#!/bin/bash

challenge=
key=
pad=false

# parse parameters
while getopts ":k:c:ph" opt; do
	case $opt in
		k)
			key="$OPTARG";;
		c)
			challenge="$OPTARG";;
		p)
			pad=true;;
		h)
			echo "Usage..."
			echo "-k secret key as hex string"
			echo "-c HMAC challenge"
			echo "-p Set this flag to left pad the challenge with zeros to 64 characters"
			exit 0;;
	esac
done

if [ $key == "" ]; then
	echo "Missing secret key..."
	exit 1
fi

if [ $challenge == "" ]; then
	echo "Missing HMAC challenge..."
	exit 1
fi

# left pad challenge string with zeros to 64 character length
if [ $pad = "true" ]; then
	l=$(echo ${#challenge})
	pad=$(perl -e "print '0' x $((64-$l))")
	challenge=$pad$challenge
fi

echo -n "$challenge" | openssl dgst -sha1 -mac HMAC -macopt hexkey:$key -binary | xxd -p
