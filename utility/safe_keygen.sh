#!/bin/bash 

KEYLENGTH=4096
CERT_SUBJECT="/C=US/ST=NC/L=ChapelHill/CN=cyberimpact.us"
CERT_DAYS=3650

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

main() {
  if [ $# -ne 3 ]; then
    usage
    exit 1
  fi

  if [ ! -e $3 ]; then
    mkdir $3
  else 
    if [ ! -d $3 ]; then
      echo "$3 already exists but is not a directory"
      exit 1
    fi
  fi

  echo "Generating $2 keys with key filename prefix $1 under $3"
  generate_keys $1 $2 $3
}

usage() {
  echo "Usage: $0 <key-filename-prefix> <number-of-keys> <key-dir>"
}

generate_keys() { 
  key_name_prefix=$1
  num_keys=$2
  key_dir=$3

  count=1
  while [ $count -le $num_keys ]
  do
    pubprivfile="${key_dir}/${key_name_prefix}${count}.pubpriv.pem"
    keyfile="${key_dir}/${key_name_prefix}${count}.key"
    pubfile="${key_dir}/${key_name_prefix}${count}.pub"
    certfile="${key_dir}/${key_name_prefix}${count}.cert.pem"
    pkcs12Certfile="${key_dir}/${key_name_prefix}${count}.cert.pfx"

    # generate combined private+public key
    openssl genpkey -algorithm rsa -pkeyopt rsa_keygen_bits:${KEYLENGTH} -outform pem -out ${pubprivfile} >& /dev/null 

    # split up into private and public keys
    openssl rsa -in ${pubprivfile} -outform PEM -pubout -out ${pubfile} >& /dev/null
    openssl rsa -in ${pubprivfile} -outform PEM -out ${keyfile} >& /dev/null
    
    # Generate self-signed certificate from key
    openssl req -new -x509 -days ${CERT_DAYS} -subj ${CERT_SUBJECT} -key ${pubprivfile} -out ${certfile} >& /dev/null

    # Generate PKCS12 (browser-importable) from PEM:
    openssl pkcs12 -inkey ${keyfile} -in ${certfile} -export -passout pass: -out ${pkcs12Certfile} >& /dev/null

    # output the hash of the generated public key
    keyhash=`${SCRIPTDIR}/hash_gen.py ${pubfile}`

    rm ${pubprivfile}
    rm ${certfile}

    echo ${key_name_prefix}${count}: ${keyhash}
    ((count += 1))
  done
  echo "Done"
}

main "$@"
