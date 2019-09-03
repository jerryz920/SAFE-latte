
export SAFE_ADDR=http://127.0.0.1:19851
export IAAS=152.3.145.38:444
. ../functions

postVMInstance $IAAS kmaster kube-image 192.168.0.2:1-65535 192.168.2.0/24 vpc-1

postEndorsementLink bob kube-image
postEndorsement bob kube-image attester 1
#postEndorsementLink alice image-builder-vm kube-image
postTrustedEndorser alice bob attester
postTrustedEndorser bob bob attester

checkAttester alice kmaster

postInstance kmaster pod1 imagenotused 192.168.2.0:1-65535
checkLaunches alice pod1 imagenotused
postInstanceConfigList kmaster pod1 containers '[ctn1,ctn2]'
checkHasConfig alice pod1 containers '[ctn1,ctn2]'
postInstanceConfigList kmaster pod1 global '[ctn1,ctn2]'
postInstanceConfigList kmaster pod1 ctn1 '[image_c1,[[k1,v1],[k2,v2]]]'
postInstanceConfigList kmaster pod1 ctn2 '[image_c2,[[k3,v3],[k4,v4]]]'

postInstance kmaster pod2 imagenotused 192.168.2.1:1-65535
postInstanceConfigList kmaster pod2 containers '[ctn1,ctn2]'
postInstanceConfigList kmaster pod2 global '[ctn1,ctn2]'
postInstanceConfigList kmaster pod2 ctn1 '[image_c3,[[k1,v1],[k2,v2]]]'
postInstanceConfigList kmaster pod2 ctn2 '[image_c2,[[k3,v3],[k4,v4]]]'

postInstance kmaster pod3 imagenotused 192.168.2.2:1-65535
postInstanceConfigList kmaster pod3 containers '[ctn1,ctn2]'
postInstanceConfigList kmaster pod3 global '[ctn1,ctn2]'
postInstanceConfigList kmaster pod3 ctn1 '[image_c1,[[k1,v1],[k2,v2]]]'
postInstanceConfigList kmaster pod3 ctn2 '[image_c1,[[k3,v3],[k5,v5]]]'

postInstance kmaster pod4 imagenotused 192.168.2.3:1-65535
postInstanceConfigList kmaster pod4 containers '[ctn1,ctn2]'
postInstanceConfigList kmaster pod4 global '[ctn1,ctn2]'
postInstanceConfigList kmaster pod4 ctn1 '[image_c1,[[k1,v1],[k2,v2]]]'
postInstanceConfigList kmaster pod4 ctn2 '[image_c2,[[k3,v3]]]'

postInstance kmaster pod5 imagenotused 192.168.2.4:1-65535
postInstanceConfigList kmaster pod5 containers '[ctn1,ctn2]'
postInstanceConfigList kmaster pod5 global '[ctn1,ctn2]'
postInstanceConfigList kmaster pod5 ctn1 '[image_c1,[[k1,v1],[k2,v2]]]'
postInstanceConfigList kmaster pod5 ctn2 '[image_c2,[[k3,v3],[k4,v5]]]'

postImageSpec alice "[image_c1,image_c2]"
postPropertySpec alice "[k5]" "[k1,k2,k3,k4]" "[[k3,v3],[k1,v1],[k2,v2],[k4,v4]]"
printf "\n\n\nchecking pod\n\n"
checkPodAttestation alice pod1
checkPodAttestation alice pod2
checkPodAttestation alice pod3
checkPodAttestation alice pod4
checkPodAttestation alice pod5
