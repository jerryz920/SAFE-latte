#export STORE_ADDR=128.105.145.138:8098
export STORE_ADDR=localhost:8098
export SAFE_CERT_DIR=types/safesets/buckets/safe/keys

for t in "$@"; do
  certurl=http://${STORE_ADDR}/${SAFE_CERT_DIR}/$t 
  printf "\n\nPulling certificate at $certurl"
  printf "\n==========================================================\n"
  curl $certurl
  printf "\n==========================================================\n"
done