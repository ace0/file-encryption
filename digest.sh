#!/bin/bash

algo=sha512
# define 64 bytes challenge
challenge=f3325d00a50b900370ba7149185573dea99d21482bc397066c3ae0f7c2f88e26
slot=2
encoding=base64
passwd=

# parse parameters
while getopts ":a:c:s:e:p:h" opt; do
	case $opt in
		a)
			algo="$OPTARG";;
		c)
			challenge="$OPTARG";;
		s)
			slot=$OPTARG;;
		e)
			encoding="$OPTARG";;
		p)
			passwd="$OPTARG";;
		h)
			echo "Usage ..."
			echo "-a set digest algorithm"
			echo "-c Yubikey challenge string"
			echo "-s Yubikey slot number for HMAC-SHA1 chalresp"
			echo "-e Output encoding"
			echo "-p password as dgst input"
			exit 0;;
	esac
done

if [ "$passwd" == "" ]; then
	echo "Empty password ..."
	exit 1
fi

dgst=$(echo -n $passwd | openssl dgst -"$algo" -mac HMAC -macopt hexkey:`sudo ykchalresp -$slot $challenge` -binary | xxd -p)

if [ "$encoding" == "base64" ]; then
	dgst=$(echo -n $dgst | openssl base64)
fi

echo $dgst | sed 's/ //g'