# Latte Kubernetes (L-Kube)

The L-Kube documentation illustrates scenarios for creating, checking,
and using of services running in pods launched from Latte Kubernetes.
It explains how code and configuration of a pod are attested using
Latte, how properties of a pod service are drawn based on endorsements
and policies, and how L-Kube is integrated to enable
attestation-based access control in applications, e.g., joint data
analytics. 

## Latte slang scripts
The Latte slang script [https://github.com/jerryz920/SAFE-latte/blob/yan/latte/safe-apps/cloud-attestation/new/latte.slang]
imports plist library [https://github.com/jerryz920/SAFE-latte/blob/yan/latte/safe-apps/cloud-attestation/plist-lib.slang]
and Latte policy slang [https://github.com/jerryz920/SAFE-latte/blob/yan/latte/safe-apps/cloud-attestation/policy.slang].
This script provides a variety of constructs for attesting Latte instances
(e.g., VM and pods), endorsing code properties (e.g., attester) and trusted endorsers,
checking policy compilance to guard service access. A common set of
latte policy rules in this script allows checks of configurations
and properties attested by instances which themselves are attested.
The following uses an end-to-end example to go through a typical process of
attesting, endorsing, and checking in Latte. It uses a bash shell
[https://github.com/jerryz920/SAFE-latte/blob/yan/latte/safe-apps/cloud-attestation/new/test_pod_local.sh] 
for invoking a Latte construct. 
  

## Attesting pods and their configurations 
This example uses Latte to attest a k8s pod and the environment in
which the k8s pod runs. As a result, the attestation and endorsements
start from the IaaS layer and extend to the layer of k8s. 

### Start a Kubernetes cluster
When an IaaS launches a Kubernetes cluster, it runs a kubernetes
master in a VM and attests to the kube image that this master
runs. 

```
postVMInstanceLocal $IAAS kmaster kube-image vpc-1
```

### Create a pod on the k8s cluster
On creating a new pod in the k8s cluster, k8s master attests to
the creation of this pod, containers inside this pod, and configurations
of both the pod and its containers. 

```
postInstanceLocal kmaster $IAAS pod1 imagenotused
postInstanceConfigList kmaster pod1 containers '[ctn1,ctn2]'
postInstanceConfigList kmaster pod1 global '[ctn1,ctn2]'
postInstanceConfigList kmaster pod1 ctn1 '[image_c1,[k1,v1],[k2,v2]]'
postInstanceConfigList kmaster pod1 ctn2 '[image_c2,[k2,v2],[k4,v4]]'
```

## Endorsing properties
Latte allows endorsements on image properties, configuration properties, and
endorsers. 

### VM image properties
One can endorse certain properties of images based on the code. 
For example, the following 
endorses the ``attester'' of a kube-image running in a VM. 

```
postEndorsement bob kube-image attester 1
```

### Use of endorsements
A principal can make use of an image endorsement by incorporating the
endorsement into its own trust wallet. The principal could set
its policy on whose endorsements it trusts.

```
postEndorsementLink bob kube-image
postTrustedEndorser alice bob attester
postTrustedEndorser bob bob attester
``` 

### Config properties

One can  endorse properties of configurations in Latte. Latte provides
three predicates to deal with config properties: Qualifier,
required, and prohibited.  The following endorses VM images and container
configurations.

```
postImagePolicy alice default "[image_c1, image_c2]"
postPropertyPolicy alice default "[ [*,k1,k2], [*,k3] ]" "[ [*,[k1,v1],[k2,v2]], [*,[k3,v3]] ]" "[ [*,k4], [*,k9] ]"
```

## Authorizing access
A service guard invokes a Latte client to check policy compliance on receiving
an access request. Latte's authorization checking ensures that not only the 
code and configuration of the requester but also the environment where the
requester resides complies with the guard's policy. 

```
checkPodAttestationLocal alice kmaster pod1
```