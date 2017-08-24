# File Encryption & Decryption

This repository contains scripts to encrypt/decrypt files using OpenSSL. The target file will be encrypted using a symmetric key. It especially aims at making asymmetric public/private key encryption easier and includes a configuration file to use a key stored on a Yubikey PIV smartcard or other pkcs11 compatible smartcards. This will encrypt the file using a symmetric key and encrypt this key using the public key. The encrypted symmetric key and file can then be shared over the internet or stored in a cloud space. The private key for decrypting the symmetric key is securely stored on the Yubikey.

The script is tested on Ubuntu. The OpenSSL config file `openssl.cnf` for pkcs11 might be adapted to your system.

In order to use public/private key encrpytion stored on a Yubikey you have to install OpenSC PKCS11 library. In Ubuntu, do
```
sudo apt-get install opensc-pkcs11
```

In addition you need to store openssl.cnf in the same folder as this script to configure pkcs11 engine. You need to adjust dynamics_path and MODULE_PATH to fit your system. Examples for Windows: dynamic_path = engine_pkcs11.dll; MODULE_PATH=C:\\Windows\\System32\\opensc-pkcs11.dll;

**Encryption using Yubikey PIV Smartcard**
```
./encryptFile -y -p 01:03 -f file_to_encrypt
```
The above example uses the key stored in slot 9d: Key Management. See https://developers.yubico.com/PIV/Introduction/Certificate_slots.html for descriptions of the different PIV slots. In this example a 256 bit symmetric key *encryption.key* will be automatically generated and encrypted using the public key stored on the smartcard. You can use a specific key using the `-k` option. To determine the key ID you can use `pkcs15-tool --list-keys`. The structure is 'Auth ID:ID'

**Decryption using Yubikey PIV Smartcard**

This example requires the public-key encrypted symmetric key *encryption.key.enc* in the same directory. You can use a specific key using the `-k` option.
```
./encryptFile -y -p 01:03 -f file_to_encrypt.enc -d
```
