export SAFE_ADDR=http://localhost:7777
export IAAS=152.3.145.38:444
. ../functions


# assume 192.168.0.0/24 is used for VM. Right now the script requires posting VM instance, since it
# delegates CIDR for upper layer.
#postVMInstance $IAAS image-builder-vm builder-image 192.168.0.1:1-65535 192.168.1.0/24 vpc-1 $IAAS
#postEndorsement $IAAS builder-image builder
postVMInstance $IAAS k8s-master kube-image vpc-1 192.168.0.2:1-65535 192.168.2.0/24

postEndorsementLink bob kube-image
postEndorsement bob kube-image attester 1
#postEndorsementLink alice image-builder-vm kube-image
postTrustedEndorser alice bob attester
postTrustedEndorser bob bob attester


# All following checks should pass
printf "\n\n checking... \n\n"
echo
checkLaunches alice $IAAS k8s-master kube-image
echo
checkProperty alice $IAAS kube-image attester 1
echo
checkTrustedEndorser alice bob attester
echo
#debug alice k8s-master attester 1
#echo
checkProperty alice $IAAS k8s-master attester 1
echo
checkAttester alice $IAAS k8s-master
echo
