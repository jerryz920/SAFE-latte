
export SAFE_ADDR=http://127.0.0.1:7777
export IAAS=152.3.145.38:444
. ../functions

postVMInstance $IAAS kmaster kube-image vpc-1 192.168.0.2:1-65535 192.168.2.0/24

postEndorsementLink bob kube-image
postEndorsement bob kube-image attester 1
#postEndorsementLink alice image-builder-vm kube-image
postTrustedEndorser alice bob attester
postTrustedEndorser bob bob attester

checkAttester alice $IAAS kmaster

postInstance kmaster $IAAS pod1 imagenotused 192.168.2.0:1-65535
checkLaunches alice kmaster pod1 imagenotused
postInstanceConfigList kmaster pod1 containers '[ctn1,ctn2]'
checkHasConfig alice kmaster pod1 containers '[ctn1,ctn2]'
postInstanceConfigList kmaster pod1 global '[ctn1,ctn2]'
postInstanceConfigList kmaster pod1 ctn1 '[image_c1,[k1,v1],[k2,v2]]'
postInstanceConfigList kmaster pod1 ctn2 '[image_c2,[k3,v3],[k4,v4]]'

postInstance kmaster $IAAS pod2 imagenotused 192.168.2.1:1-65535
postInstanceConfigList kmaster pod2 containers '[ctn1,ctn2]'
postInstanceConfigList kmaster pod2 global '[ctn1,ctn2]'
postInstanceConfigList kmaster pod2 ctn1 '[image_c3,[k1,v1],[k2,v2]]'
postInstanceConfigList kmaster pod2 ctn2 '[image_c2,[k3,v3],[k4,v4]]'

postInstance kmaster $IAAS pod3 imagenotused 192.168.2.2:1-65535
postInstanceConfigList kmaster pod3 containers '[ctn1,ctn2]'
postInstanceConfigList kmaster pod3 global '[ctn1,ctn2]'
postInstanceConfigList kmaster pod3 ctn1 '[image_c1,[k1,v1],[k2,v2]]'
postInstanceConfigList kmaster pod3 ctn2 '[image_c1,[k3,v3],[k5,v5]]'

postInstance kmaster $IAAS pod4 imagenotused 192.168.2.3:1-65535
postInstanceConfigList kmaster pod4 containers '[ctn1,ctn2]'
postInstanceConfigList kmaster pod4 global '[ctn1,ctn2]'
postInstanceConfigList kmaster pod4 ctn1 '[image_c1,[k1,v1],[k2,v2]]'
postInstanceConfigList kmaster pod4 ctn2 '[image_c2,[k3,v3]]'

postInstance kmaster $IAAS pod5 imagenotused 192.168.2.4:1-65535
postInstanceConfigList kmaster pod5 containers '[ctn1,ctn2]'
postInstanceConfigList kmaster pod5 global '[ctn1,ctn2]'
postInstanceConfigList kmaster pod5 ctn1 '[image_c1,[k1,v1],[k2,v2]]'
postInstanceConfigList kmaster pod5 ctn2 '[image_c2,[k3,v3],[k4,v5]]'

postImagePolicy alice policy1 "[image_c1,image_c2]"
postPropertyPolicy alice policy1 "[image_c1,k1,k2]" "[image_c1,[k1,v1],[k2,v2]]" "[image_c1,k4]"
postPropertyPolicy alice policy1 "[image_c2,k3]" "[image_c2,[k3,v3]]" "[image_c2,k9]"

printf "\n\n\nchecking pod\n\n"
# pod1, pod4, and pod5 should pass the check
checkPodAttestation alice kmaster pod1 policy1
checkPodAttestation alice kmaster pod2 policy1
checkPodAttestation alice kmaster pod3 policy1
checkPodAttestation alice kmaster pod4 policy1
checkPodAttestation alice kmaster pod5 policy1
