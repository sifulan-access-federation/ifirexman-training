####################################
#!/bin/bash 
G=$1
H=$2
XMLSECTOOLDIR="/xmlsectool-2.0.0"
Y="/metadata/tempfile"
if [ $G -eq "provider" ]; then
 wget --no-check-certificate -O $Y https://fedmanager.sifulan.my/tools/sync_metadata/metadataslist/${H}
else
 wget --no-check-certificate -O $Y https://fedmanager.sifulan.my/tools/sync_metadata/metadataslist
fi

for i in `cat ${Y}`; do
   group=`echo $i|awk -F ";" '{ print $1 }'|tr -d ' '`
   name=`echo $i|awk -F ";" '{ print $2 }'|tr -d ' '`
   srcurl=`echo $i|awk -F ";" '{ print $3 }'|tr -d ' '`

   #tempofileoutput="/tmp/${name}"
   dstoutput="/metadata/signedmetadata/${group}/${name}"
   if [ ! -d "$dstoutput" ]; then
      mkdir -p $dstoutput
   fi
   ${XMLSECTOOLDIR}/xmlsectool.sh --sign --digest SHA-256 --referenceIdAttributeName ID --certificate /cert/cert.crt  --key /cert/cert.key  --keyPassword ${CERTPASSWORD} \
     --outFile ${dstoutput}/metadata.xml --inUrl ${srcurl}
done

rm ${Y}

##################################
