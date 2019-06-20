#!/usr/bin/env python
import hashlib, base64, sys

from Crypto.PublicKey import RSA

f = open(sys.argv[1], 'r')
r = RSA.importKey(f.read(), passphrase='')

s = hashlib.sha256()
s.update(r.exportKey(format='DER'))

encoded = base64.urlsafe_b64encode(s.digest())

print(encoded.decode('utf-8'))
