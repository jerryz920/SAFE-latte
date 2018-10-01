#!/bin/bash

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

inc() {
  return `echo "scale=8; $1 + 1" | bc`
}

generate_keys() { 
  key_name_prefix=$1
  num_keys=$2
  key_dir=$3

  count=1
  while [ $count -le $num_keys ]
  do
    keyfile="${key_dir}/${key_name_prefix}${count}.key"
    pubfile="${key_dir}/${key_name_prefix}${count}.pub"
    certfile="${key_dir}/${key_name_prefix}${count}.cert.pem"
    pkcs12Certfile="${key_dir}/${key_name_prefix}${count}.cert.pfx"

    # Generate key pair
    ssh-keygen -t rsa -b 4096 -P "" -f ${keyfile}  -q
    ssh-keygen -e -m PEM -f ${keyfile}.pub > ${pubfile}
    rm ${keyfile}.pub

    # Generate self-signed certificate from SSH-created public/private keys:
    subj="/C=US/ST=NC/L=Durham/CN=www.cs.duke.edu"
    openssl req -new -x509 -days 365 -subj ${subj} -key ${keyfile} -out ${certfile}

    # Generate PKCS12 (browser-importable) from PEM:
    openssl pkcs12 -inkey ${keyfile} -in ${certfile} -export -passout pass: -out ${pkcs12Certfile}

    inc $count
    count=$?
    printf "."
  done
  printf "\nDone\n"
}

main "$@"
