#!/bin/bash

# FEDERATION
bash sign.sh " "

cp /metadata/signedmetadata/federation/FEDERATION/metadata.xml /www/metadata.xml

# EDUGAIN
wget https://mds.edugain.org/edugain-v2.xml -O /metadata/edugain-metadata-feed.xml
pyff --loglevel=INFO edugain.fd
chmod +x /metadata/edugain-export-metadata.xml
cp /metadata/edugain-export-metadata.xml /www/edugain-export-metadata.xml

# FEDERATION FULL
pyff --loglevel=INFO full.fd
chmod +x /metadata/full-metadata.xml
cp /metadata/full-metadata.xml /www/full-metadata.xml