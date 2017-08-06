#!/bin/bash
file=
key=
key_default_name=encryption
pubkey=
cipher=aes-256-cbc

do_shift=2
decrypt=false
outfile=
yubikey=false
encoding=base64

# parse parameters
while getopts ":f:k:K:c:dp:ye:o:h" opt; do
	case $opt in
		f)
			file="$OPTARG";;
		k)
			key="$OPTARG"
			do_shift=$((do_shift+2));;
		K)
			key_default_name="$OPTARG"
			do_shift=$((dho_shift+2));;
		c)
			cipher="$OPTARG"
			do_shift=$((do_shift+2));;
		d)
			decrypt=true;;
		o)
			outfile="$OPTARG"
			do_shift=$((do_shift+2));;
		p)
			pubkey="$OPTARG"
			do_shift=$((do_shift+2));;
		y)
			yubikey=true
			do_shift=$((do_shift+1));;
		e)
			encoding="$OPTARG"
			do_shift=$((do_shift+2));;
		h)
			echo "Usage ..."
			echo "-k path to the keyfile"
			echo "-f path to file to encrypt"
			echo "-d set this flag to decrypt file"
			echo "-o optional output filename"
			echo "-p optional public RSA key to use for encryption. In this case, the encryption key will be encrypted using the RSA key. To decrypt the data, the corresponding private RSA key is needed along the encrypted encryption key."
			echo "-c encryption cipher to use. Defaults to aes-256-cbc"
			echo "-y use yubikey PIV smartcard for asymmetric encryption. Set -k to slot to use, e.g. 01:03 for slot 9d"
			echo "-e set encoding of encrypted symmetric key for public/private key encryption. Currently 'base64' or otherwise binary encoding"
			echo ""
			echo "In order to use public/private key encrpytion stored on a Yubikey you have to install OpenSC PKCS11 library. In Ubuntu, do"
			echo "    sudo apt-get install opensc-pkcs11"
			echo "In addition you need to store openssl.cnf in the same folder as this script to configure pkcs11 engine. You need to adjust dynamics_path and MODULE_PATH to fit your system. Examples for Windows: dynamic_path = engine_pkcs11.dll; MODULE_PATH=C:\\Windows\\System32\\opensc-pkcs11.dll; I only tested the script on Ubuntu, so I am not familiar with the settings for other OS."
			echo ""
			echo "Example using Yubikey PIV Smartcard"
			echo "    ./encryptFile -y -p 01:03 -f file_to_encrypt"
			echo "The above example uses slot 9d: Key Management. See https://developers.yubico.com/PIV/Introduction/Certificate_slots.html"
			echo "In this example the symmetric key encryption.key will be automatically generated and encrypted using the public key stored on the smartcard"
			echo "To determine the key ID you can use pkcs15-tool --list-keys. The structure is 'Auth ID:ID'"
			echo ""
			echo "Decryption of file, requires presence of the public-key encrypted symmetric key encryption.key.enc"
			echo "    ./encryptFile -y -p 01:03 -f file_to_encrypt.enc -d"
			exit 0;;
	esac
done

shift $do_shift

if [ "$file" == "" ]; then
	echo "Missing input file..."
	exit 1
fi

# if key is not defined construct default key name
if [ "$key" == "" ]; then
	if [ "$decrypt" = "false" ]; then
		key=$key_default_name.key
	else
		key=$key_default_name.key.enc
	fi
fi

# If key does not exist, construct a new one if file is encrypted, otherwise abort
if [ ! -e "$key" ]; then
	if [ "$decrypt" = "false" ]; then
		echo "Generating new random 32 bytes symmetric encryption key"
		openssl rand -hex 32 > $key
	else
		echo "Missing decryption key file..."
		exit 1
	fi
fi

if [ "$outfile" == "" ] && [ "$decrypt" = "false" ]; then
	outfile="$file".enc
elif [ "$outfile" == "" ]; then
	outfile=$(echo $file | sed 's/.enc//').decrypted
fi

if [ "$pubkey" == "" ]; then
	# symmetric encryption/decryption using single private key
	openssl enc -"$cipher" -a -pass file:$key -in $file -out $outfile $@
else
	opts=
	if [ "$yubikey"="true" ]; then
		export OPENSSL_CONF=./openssl.cnf
		opts="-keyform engine -engine pkcs11"
	fi
	
	if [ "$decrypt" = "false" ]; then
		# asymmetric encryption using private key and someone else public key
		
		# encrypt the key using other person's public key
		openssl rsautl -encrypt $opts -inkey $pubkey -pubin -in $key -out $key.enc $@
		
		# base64 encode encrypted symmetric key
		if [ $encoding == "base64" ]; then
			cat $key.enc | openssl base64 > $key.enc.base64 && mv $key.enc.base64 $key.enc
		fi
		
		# encrypt the file
		openssl enc -"$cipher" -a -pass file:$key -in $file -out $outfile
	else
		# asymmetric decryption using own public key-encrypted key and private key
		shift 1
		
		# base64 decode encrypted symmetric key
		if [ $encoding == "base64" ]; then
			cat $key | openssl base64 -d > "$key.bin" && mv $key.bin $key
		fi
		
		newkey=$(echo $key | sed 's/.enc//')
		# decrypt key
		openssl rsautl -decrypt $opts -inkey $pubkey -in $key -out $newkey.bin $@
		# decrypt file
		openssl enc -d -"$cipher" -a -pass file:$newkey.bin -in $file -out $outfile
	fi
fi
