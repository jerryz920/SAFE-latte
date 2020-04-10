
export SAFE_ADDR=http://127.0.0.1:7777
export IAAS=152.3.145.38:444
. ../functions

postVMInstanceLocal $IAAS kmaster kube-image vpc-1

postEndorsementLink bob kube-image
postEndorsement bob kube-image attester 1
#postEndorsementLink alice image-builder-vm kube-image
postTrustedEndorser alice bob attester
postTrustedEndorser bob bob attester

# Special format:
# checkAttester authorizer parentInstance targetInstance
checkAttesterLocal alice $IAAS kmaster

# Special format:
# postInstanceLocal authorizer parentInstance newInstance newImage
postInstanceLocal kmaster $IAAS pod1 imagenotused 
postInstanceConfigList kmaster pod1 containers '[ctn1,ctn2]'
postInstanceConfigList kmaster pod1 global '[ctn1,ctn2]'
postInstanceConfigList kmaster pod1 ctn1 '[image_c1,[k1,v1],[k2,v2]]'
postInstanceConfigList kmaster pod1 ctn2 '[image_c2,[k2,v2],[k4,v4]]'

postInstanceLocal kmaster $IAAS pod2 imagenotused 
postInstanceConfigList kmaster pod2 containers '[ctn1,ctn2]'
postInstanceConfigList kmaster pod2 global '[ctn1,ctn2]'
postInstanceConfigList kmaster pod2 ctn1 '[image_c3,[k1,v1],[k2,v2]]'
postInstanceConfigList kmaster pod2 ctn2 '[image_c2,[k3,v3],[k4,v4]]'

postInstanceLocal kmaster $IAAS pod3 imagenotused
postInstanceConfigList kmaster pod3 containers '[ctn1,ctn2]'
postInstanceConfigList kmaster pod3 global '[ctn1,ctn2]'
postInstanceConfigList kmaster pod3 ctn1 '[image_c1,[k1,v1],[k2,v2]]'
postInstanceConfigList kmaster pod3 ctn2 '[image_c1,[k2,v2],[k5,v5]]'

postInstanceLocal kmaster $IAAS pod4 imagenotused
postInstanceConfigList kmaster pod4 containers '[ctn1,ctn2]'
postInstanceConfigList kmaster pod4 global '[ctn1,ctn2]'
postInstanceConfigList kmaster pod4 ctn1 '[image_c1,[k1,v1],[k2,v2]]'
postInstanceConfigList kmaster pod4 ctn2 '[image_c2,[k3,v3]]'

postInstanceLocal kmaster $IAAS pod5 imagenotused
postInstanceConfigList kmaster pod5 containers '[ctn1,ctn2]'
postInstanceConfigList kmaster pod5 global '[ctn1,ctn2]'
postInstanceConfigList kmaster pod5 ctn1 '[image_c1,[k1,v1],[k2,v2]]'
postInstanceConfigList kmaster pod5 ctn2 '[image_c2,[k3,v3],[k4,v5]]'

# Image whitelist
# postImagePolicy <Principal> <PolicyID> <ImageList> 
postImagePolicy alice default "[image_c1, image_c2]"

# Lists of required keys per container,  lists of qualifier properties
# (KV) per container, and lists of prohibited keys per container
#
# postPropertyPolicy <Principal> <PolicyID> <RequiredKeysPerImg> <QualifierPropsPerImg> <ProhibitedKeysPerImg>
postPropertyPolicy alice default "[image_c1,k1,k2]" "[image_c1,[k1,v1],[k2,v2]]" "[image_c1,k4]"
postPropertyPolicy alice default "[image_c2,k3]" "[image_c2,[k3,v3]]" "[image_c2,k9]"

printf "\n\n\nchecking pod\n\n"
# Special format:
# checkPodAttestationLocal authorizer parentInstanceIdAsBearerref targetInstanceId
# checks on pod4 and pod5 should pass, according to their attestations and alice's policy.
checkPodAttestationLocal alice kmaster pod1
checkPodAttestationLocal alice kmaster pod2
checkPodAttestationLocal alice kmaster pod3
checkPodAttestationLocal alice kmaster pod4
checkPodAttestationLocal alice kmaster pod5
