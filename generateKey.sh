#!/bin/sh
# Generate a random secret key in hex format

bits=256
outfile=

# parse parameters
while getopts ":b:o:h" opt; do
	case $opt in
		b)
			bits=$OPTARG;;
		o)
			outfile="$OPTARG";;
		h)
			echo "Usage ..."
			echo "-b keysize in bits"
			echo "-o output file. By default the key is printed to stdout"
			exit 0;;
	esac
done

if [ "$outfile" == "" ];  then
	openssl rand -hex $((bits/8))
else
	openssl rand -hex $((bits/8)) > "$outfile"
fi
