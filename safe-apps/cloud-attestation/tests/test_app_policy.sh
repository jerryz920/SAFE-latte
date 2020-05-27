
export SAFE_ADDR=http://127.0.0.1:7777
export IAAS=152.3.145.38:444
. ../functions

postVMInstance $IAAS kmaster kube-image vpc-1 172.16.0.2:1-65535 192.168.2.0/24

postEndorsementLink bob kube-image
#postEndorsementLink bob trustPolicy/policy1
postEndorsement bob kube-image attester 1
#postEndorsementLink alice image-builder-vm kube-image
postTrustedEndorser alice bob attester
postAndDLinkTrustedEndorser alice bob trustPolicy endorsements/trustPolicy/policy1
#postTrustedEndorser alice bob trustPolicy
#postEndorsementLink alice trustPolicy/policy1
#postTrustedEndorser alice alice trustPolicy
postTrustedEndorser bob bob attester

checkAttester alice $IAAS kmaster

postInstance kmaster $IAAS pod1 imagenotused 192.168.2.1:1-65535
checkLaunches alice kmaster pod1 imagenotused
postInstanceConfigList kmaster pod1 containers '[ctn1,ctn2]'
checkHasConfig alice kmaster pod1 containers '[ctn1,ctn2]'
postInstanceConfigList kmaster pod1 global '[ctn1,ctn2]'
postInstanceConfigList kmaster pod1 ctn1 '[image_c1,[k1,v1],[k2,v2]]'
postInstanceConfigList kmaster pod1 ctn2 '[image_c2,[k3,v3],[k4,v4]]'

postInstance kmaster $IAAS pod2 imagenotused 192.168.2.2:1-65535
postInstanceConfigList kmaster pod2 containers '[ctn1,ctn2]'
postInstanceConfigList kmaster pod2 global '[ctn1,ctn2]'
postInstanceConfigList kmaster pod2 ctn1 '[image_c3,[k1,v1],[k2,v2]]'
postInstanceConfigList kmaster pod2 ctn2 '[image_c2,[k3,v3],[k4,v4]]'

postInstance kmaster $IAAS pod3 imagenotused 192.168.2.3:1-65535
postInstanceConfigList kmaster pod3 containers '[ctn1,ctn2]'
postInstanceConfigList kmaster pod3 global '[ctn1,ctn2]'
postInstanceConfigList kmaster pod3 ctn1 '[image_c1,[k1,v1],[k2,v2]]'
postInstanceConfigList kmaster pod3 ctn2 '[image_c1,[k3,v3],[k5,v5]]'

postInstance kmaster $IAAS pod4 imagenotused 192.168.2.4:1-65535
postInstanceConfigList kmaster pod4 containers '[ctn1,ctn2]'
postInstanceConfigList kmaster pod4 global '[ctn1,ctn2]'
postInstanceConfigList kmaster pod4 ctn1 '[image_c1,[k1,v1],[k2,v2]]'
postInstanceConfigList kmaster pod4 ctn2 '[image_c2,[k3,v3]]'

postInstance kmaster $IAAS pod5 imagenotused 192.168.2.5:1-65535
postInstanceConfigList kmaster pod5 containers '[ctn1,ctn2]'
postInstanceConfigList kmaster pod5 global '[ctn1,ctn2]'
postInstanceConfigList kmaster pod5 ctn1 '[image_c1,[k1,v1],[k2,v2]]'
postInstanceConfigList kmaster pod5 ctn2 '[image_c2,[k3,v3],[k4,v5]]'

postInstance kmaster $IAAS pod6 imagenotused 192.168.2.6:1-65535
postInstanceConfigList kmaster pod6 containers '[ctn1,ctn2]'
postInstanceConfigList kmaster pod6 global '[ctn1,ctn2]'
postInstanceConfigList kmaster pod6 ctn1 '[image_c1,[k1,v6],[k2,v7],[k4,v4]]'
postInstanceConfigList kmaster pod6 ctn2 '[image_c2,[k1,v1],[k4,v5]]'


postPodPolicy bob policy1 leak-free
postImagePolicy bob policy1 "[image_c1,image_c2]"
postProhibitedPolicy bob policy1 "[image_c1,k5]" 
postProhibitedPolicy bob policy1 "[image_c2,k5]" 
postRequiredPolicy bob policy1 "[image_c1,k1,k2]"
postRequiredPolicy bob policy1 "[image_c2,k3]"
postQualifierPolicy bob policy1 "[image_c1,[k1,v1]]"
postQualifierPolicy bob policy1 "[image_c2,[k4,v4]]"

# Among the queries, only the check on the first pod would pass.
printf "\n\n\nchecking pods\n\n"
checkPodByPolicy alice kmaster pod1 policy1
checkPodByPolicy alice kmaster pod2 policy1
checkPodByPolicy alice kmaster pod3 policy1
checkPodByPolicy alice kmaster pod4 policy1
checkPodByPolicy alice kmaster pod5 policy1

# All of the following checks must pass
debugCheck1 alice kmaster pod1 policy1
#debugCheck2 alice kmaster pod1 policy1
checkHasConfig alice kmaster pod1 ctn1 '[image_c1,[k1,v1],[k2,v2]]'
#debugCheck3 alice kmaster pod1 policy1 "[ctn2]"
debugCheck4 alice image_c1 "[image_c1, image_c2]"
debugCheck4 alice image_c1 "[image_c1]"

# This one should fail
debugCheck4 alice image_c1 "[image_c2]"


# Using alice's own policy]
postPodPolicy alice policy1 leak-free
postImagePolicy alice policy1 "[image_c1,image_c2,image_c3]"
postProhibitedPolicy alice policy1 "[image_c1,k5]"
postProhibitedPolicy alice policy1 "[image_c2,k5]"
postRequiredPolicy alice policy1 "[image_c1,k1,k2]"
postRequiredPolicy alice policy1 "[image_c2,k1]"
postQualifierPolicy alice policy1 "[image_c1,[k4,v4]]"
postQualifierPolicy alice policy1 "[image_c2,[k1,v1]]"
postEndorsementLink alice trustPolicy/policy1

# All following checks except for the first one and the last one would fail.
checkPodAttestation alice kmaster pod1 policy1
checkPodAttestation alice kmaster pod2 policy1
checkPodAttestation alice kmaster pod3 policy1
checkPodAttestation alice kmaster pod4 policy1 
checkPodAttestation alice kmaster pod5 policy1
checkPodAttestation alice kmaster pod6 policy1


# Install policy1 for admission of alice's tag0
postGroupAdmissionPolicy alice alice:tag0 "leak-free" bob


# Authorizer frank issues the following checks using alice:tag0
# pod1 and pod6 can pass this check
printf "\n\n\nchecking pods using a tag\n\n"
checkPodAccess frank kmaster pod1 alice:tag0
checkPodAccess frank kmaster pod2 alice:tag0
checkPodAccess frank kmaster pod3 alice:tag0
checkPodAccess frank kmaster pod4 alice:tag0
checkPodAccess frank kmaster pod5 alice:tag0
checkPodAccess frank kmaster pod6 alice:tag0