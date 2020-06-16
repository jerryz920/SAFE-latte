# Latte Kubernetes (L-Kube)

The L-Kube documentation illustrates scenarios for creating, checking,
and using attestations of services running in pods launched from Latte Kubernetes.
It explains how code and configuration of a pod are attested through
Latte, how properties of a pod service are drawn based on endorsements
and policies of involved parties, and how L-Kube can be integrated to enable
attestation-based access control in applications, e.g., joint data
analytics. 

## Latte Slang scripts
The [Latte Slang script](latte.slang)
imports [plist library](plist-lib.slang)
and [Latte policy Slang](policy.slang).
These Slang scripts provide a variety of constructs for attesting Latte instances
(e.g., VMs and pods), endorsing code properties (e.g., attester) and trusted endorsers,
and checking policy compilance to guard service access. A common set of
resuable latte policy rules provided in the scripts allows to check configurations
and properties attested by instances which themselves are attested.
The following sections walk through a typical process of
attesting, endorsing, and checking in Latte using an end-to-end running example.
In this example, a test uses a bash shell [script](tests/test_app_policy.sh) 
for invoking a Latte construct. 
  

## Attesting Latte instances
We use Latte to attest a k8s pod and the environment in
which the k8s pod runs. As a result, attestations and endorsements
start from the IaaS layer and extend to the layer of k8s. 

### Start a Kubernetes cluster
When an IaaS launches a Kubernetes cluster, it runs a kubernetes
master in a VM and attests to the kube image that this master
runs. The attestation can also include statements about the network
address of this VM and the range of IP addresses allocated for
pods on the k8s cluster. In this example, the k8s master belongs to a
VPC (i.e., vpc-1), uses an IP address
172.16.0.2 and a port range 0-65535, and is assigned an IP range (CIDR)
192.168.2.0/24 for pods to be launched from it.

```
postVMInstance $IAAS kmaster kube-image vpc-1 172.16.0.2:0-65535 192.168.2.0/24
```

### Create a pod on the k8s cluster

On creation of a new pod, k8s master attests to the network
address and the manifest
of this pod. Network address attested by k8s master is comprised of two
components: an IP address and a port range. In this example, pod1 is on
IP address 192.168.2.1 and owns a port range 0-65535; pod6 is on 
IP address 192.168.2.6 and owns the same port range as pod1 does. 
An attestation of a pod also includes attestation of each container
inside this pod, and the configuration
of the image with which the container runs. The *image configuration* 
associated to a running container is captured in an attestation using 
a *list* of configuration key-value tuples which
themselves are also represented as lists. 

<!--  ``$IAAS'' uses an environment
variable holding the ID of the IAAS underneath.
-->

```
postInstance kmaster $IAAS pod1 imagenotused 192.168.2.1:0-65535
postInstanceConfigList kmaster pod1 containers '[ctn1,ctn2]'
postInstanceConfigList kmaster pod1 global '[ctn1,ctn2]'
postInstanceConfigList kmaster pod1 ctn1 '[image_c1,[k1,v1],[k2,v2]]'
postInstanceConfigList kmaster pod1 ctn2 '[image_c2,[k3,v3],[k4,v4]]'
```

```
postInstance kmaster $IAAS pod6 imagenotused 192.168.2.6:0-65535
postInstanceConfigList kmaster pod6 containers '[ctn1,ctn2]'
postInstanceConfigList kmaster pod6 global '[ctn1,ctn2]'
postInstanceConfigList kmaster pod6 ctn1 '[image_c1,[k1,v6],[k2,v7],[k4,v4]]'
postInstanceConfigList kmaster pod6 ctn2 '[image_c2,[k1,v1],[k4,v5]]'
```

## Endorsing
Latte allows endorsements on image properties, configuration properties, and
the endorsers themselves. 

### Code properties 
One can endorse certain properties of an image based on the code included in
the image. An open-source community might endorse that a certain release of TLS
they work on is *no-heartbleed*. L-Kube itself uses properties such as *attester*, *builder*, and *endorser*
to facilitate the verification of attestation, image build 
information, and endorsements. 
For example, with the following commands Bob 
endorses on the property of *attester* for kube-image that kmaster runs.
Bob then stores the link to this endorsement into his *trust hub*.

```
postEndorsement bob kube-image attester 1
postEndorsementLink bob kube-image
```


### Configuration sets

An authorization ultimately asserts certain properties for images
and their configurations. An authorizer may only
accept images from a vetted whitelist, and may not allow an image configured
in an arbitrary way. For example, safety-sensitive configuration
must be unset, set, or set in particular ways, depending on application
context. L-Kube provides *configuration sets* to support checks on a common set of configuration properties.
A *configuration set* uses *property lists*, each of which is a predicated list representation of configuration targeting a particular property,
to faciliate expression, interpretation, and evaluation
for three categories of configuration properties: *prohibited*, *required*, and *qualifier*.
These three properties are used to denote configurations that must not be present,
must be present, and must be specified in a certain way, respectively. 
In this sense, a configuration set acts as a policy that governs how a configuration would be accepted. 
In our example, Alice publishes a configuration set policy1 for endorsing property *leak-free*.
It accrues the specifications of this configuration set by publishing what are
acceptable container images, and for each image what are the prohibited 
configuration (by keys), the required configuration (by
keys), and the qualifier configuration 
(by key-value tuples). Note that prohibited, required, and qualifier configurations are 
all property lists.

```
postPodPolicy ailce policy1 leak-free
postImagePolicy alice policy1 "[image_c1,image_c2,image_c3]"
postRequiredPolicy alice policy1 "[image_c1,k1,k2]"
postRequiredPolicy alice policy1 "[image_c2,k1]"
postQualifierPolicy alice policy1 "[image_c1,[k4,v4]]"
postQualifierPolicy alice policy1 "[image_c2,[k1,v1]]"
postProhibitedPolicy alice policy1 "[image_c1,k5]"
postProhibitedPolicy alice policy1 "[image_c2,k5]"
postEndorsementLink alice trustPolicy/policy1
```


### Endorsements of endorsers
A principal can make use of an image/configuration endorsement by incorporating this
endorsement along with a declaration of the issuer as a trusted endorser. This is accomplished via logic-set
linking of SAFE. The principal can choose to link an interested endorsement 
(or a trust hub) to a set of its own that adds an endorsement of the endorser:
specifying  whose endorsements the principal trusts and on what endorsable property.
For example, Alice can optionally accept Bob's endorsements on
properties *attester* and *trustPolicy*. Of course, Alice accepts the endorsements made by itself. 

```
postTrustedEndorser alice bob attester
postTrustedEndorser alice bob trustPolicy
postTrustedEndorser alice alice trustPolicy
``` 

## Authorizing
An authorizor invokes a Latte guard in Slang to check if 
attestations, configurations, and related endorsements of a requester
together meet the specification of a particular policy before it
grants access or allocates resources
to the requester. L-Kube uses tag-based access control.



### Tag-based access control
In tag-based access control,  file access is granted based on tag privilege. A file owner associates to a file an access tag, which 
indicates a privilege that must be acquired before an access to this file can be permitted. The access tag could be under
management of the principal of the file owner, but in general it could be under any principal. A managing
principal uses standard [STRONG](../strong) group library to establish and operate a tag, e.g., adding and removing
members into/from a tag, delegating and revoking authority of membership to/from another principal. In L-Kube,
a tag-managing principal uses STRONG to install a member policy for this tag based on an instance's attestion and
an endorsed property of this attestation. For example, Alice installs a policy on its tag that requires an instance to 
have a property of *leak-free* and this property to be anchored at trusted
endorser bob.  Of course, Alice accepts itself as a trusted endorser. Note that as in STRONG,
an access tag in L-Kube is represented by a self-certifying ID, a string containing the ID of the tag's managing principal
and an identifying substring of the tag.

```
postGroupAdmissionPolicy alice alice:tag0 "leak-free" bob
```


### Plugging in a configuration set from a trusted endorser

After a principal installs a member policy for a tag, this tag owner adpopts the specified 
endorser as a trusted source and delegates endorsement 
of the required instance property to this endorser.
Therefore, the endorser is eligible to publish a trusted configuration set
for endorsing the desired property.
For example, Bob sets up a configuration set named policy1 and associates it to the endorsement of
security property leak-free, as shown in the commands below. 

```
postPodPolicy bob policy1 leak-free
postImagePolicy bob policy1 "[image_c1,image_c2]"
postRequiredPolicy bob policy1 "[image_c1,k1,k2]"
postRequiredPolicy bob policy1 "[image_c2,k3]"
postQualifierPolicy bob policy1 "[image_c1,[k1,v1]]"
postQualifierPolicy bob policy1 "[image_c2,[k4,v4]]"
postProhibitedPolicy bob policy1 "[image_c1,k5]"
postProhibitedPolicy bob policy1 "[image_c2,k5]"
```

Alice could also explicitly  adopt Bob's configuration set by endorsing Bob as a trusted policy source. Note that 
here it uses SAFE's *direct linking* to incorporate the desired configuration set into this
endorsement of trusted endorser. This linking structure prunes the inference context at authorization time
and can dramatically reduce resource consumption (e.g., memory footprint), 
and delay of property proving on the authorizer.

 
```
postAndDLinkTrustedEndorser alice bob trustPolicy endorsements/trustPolicy/policy1
```



### Compliance check
In joint data analytics, a storage guard uses a Latte client
to check compliance on the arrival of
an access request. Authorization checks by L-Kube ensure that not only the
code and configuration of the requester but also the underlying execution
environment where the
requester resides all comply with the guard's policy. The command below
issues for authorizer Frank a request to check if pod1 has access privilege of tag0 under Alice,
i.e., alice:tag0. The authorizer accepts trusted endorsers registered on the tag and the attesters
accepted by the tag owner, verifies if the requester pod1 has a valid attestation, and evaluates 
the attestation against endorsed configuration set(s) to check compliance.   This authorization
check will pass.

```
checkPodAccess frank kmaster pod1 alice:tag0
```
