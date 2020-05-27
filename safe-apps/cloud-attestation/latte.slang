import("./plist-lib.slang").
import("./policy.slang").
import("../strong/strong.slang").

//////////////////////////////////////////////////////
// Enviroments
//////////////////////////////////////////////////////
// Envs from Latte default
defenv IaaS() :- "152.3.145.38:444".
defenv PropertyAttester() :- "attester".
defenv PropertyVpcId() :- "vpc-id".

//////////////////////////////////////////////////////
// Rulesets
//////////////////////////////////////////////////////
// Rulesets of Latte library

defcon consTrustWallet() :-
{
    label("trustWallet").
    trustedCloudProvider($IaaS).
}.

definit consTrustWallet().

defcon consLibraryRules() :-
{
    label("LKubeLibraryRules").

    launches(Instance, Image) :-
        H : runs(Instance, Image),
        attester(H).

    attester(Instance) :-
        trustedCloudProvider(Instance).

    attester(Instance) :-
        hasProperty(Instance, 'attester', 1).

    hasConfig(Instance, Name, Value) :-
        H: config(Instance, Name, Value),
        attester(H).

    hasProperty(Obj, Property, Value) :-
        endorse(Obj, Property, Value).

    hasProperty(Obj, Property, Value) :-
        H: endorse(Obj, Property, Value),
        trustedEndorserOn(Property, H).

    hasProperty(Instance, Property, Value) :-
        launches(Instance, Image),
        hasProperty(Image, Property, Value).

    hasProperty(Instance, Property, PolicyID) :-
        hasPolicy(PolicyID, "podProperty", Property),
        checkCompliance(Instance, PolicyID).

    checkPodOnTag(Instance, Tag) :-
        authPodToUser(Instance, User),
        membership(Tag, User).

    checkPodOnTag(Instance, Tag) :-
        membership(Tag, Instance).

    checkCompliance(Instance, Policy) :-
        approvePodByPolicy(Instance, Policy),
        \+( denyPodByPolicy(Instance, Policy) ).

    // This rule below is included in policy.slang
    //hasPolicy(PolicyID, Name, Value) :-
    //    policy(PolicyID, Name, Value).

    // Approve a pod by checking it against a whitelist of images,
    // a list of qualifier config KV pairs, a list of required config
    // keys specified by a policy (which is identified by a policy ID).
    approvePodByPolicy(Pod, PolicyID) :- 
        hasConfig(Pod, 'containers', Containers),
        approveCtnByImagePolicy(Pod, Containers, PolicyID),
        approveCtnByQualifiedKvs(Pod, Containers, PolicyID),
        approveCtnByRequiredKeys(Pod, Containers, PolicyID).

    /// Image handling
    approveCtnByImagePolicy(Pod, [Ctn|Rest], PolicyID) :-
        hasConfig(Pod, Ctn, [Image|_]),
        hasPolicy(PolicyID, "image", WhiteListImages),
        approveImage(Image, WhiteListImages),
        approveCtnByImagePolicy(Pod, Rest, PolicyID).

    /// Image matching polices
    matchImage(Image, Matcher) :-
        hasProperty(Image, Prop, 1).

    // Allow wildcard
    matchImage(_, any).

    matchImage(Image, Image).

    approveCtnByImagePolicy(_, [], _).

    // Handle image: whitelist, or an endorsed property
    approveImage(Image, [Prop|_]) :-
        matchImage(Image, Prop).

    approveImage(Image, [_|Rest]) :-
        approveImage(Image, Rest).

    // Handle Required Keys and QualifiedKvs
    approveCtnByQualifiedKvs(Pod, [Ctn|Rest], PolicyID) :-
        hasConfig(Pod, Ctn, [Image|Config]),
        hasPolicy(PolicyID, "qualifier", [ImageMatcher|QualifiedKvs]),
        matchImage(Image, ImageMatcher),
        esubseq(QualifiedKvs, Config),
        approveCtnByQualifiedKvs(Pod, Rest, PolicyID).

    approveCtnByQualifiedKvs(_, [], _).

    approveCtnByRequiredKeys(Pod, [Ctn|Rest], PolicyID) :-
        hasConfig(Pod, Ctn, [Image|Config]),
        hasPolicy(PolicyID, "required", [ImageMatcher|RequiredKeys]),
        matchImage(Image, ImageMatcher),
        propsPresent(RequiredKeys, Config),
        approveCtnByRequiredKeys(Pod, Rest, PolicyID).

    approveCtnByRequiredKeys(_, [], _).


    // Deny check on a pod's config against a policy
    denyPodByPolicy(Pod, PolicyID) :-
        hasConfig(Pod, 'containers', Containers),
        denyCtnByProhibitedKeys(Pod, Containers, PolicyID).

    denyCtnByProhibitedKeys(Pod, [Ctn|_], PolicyID) :-
        hasConfig(Pod, Ctn, [Image|Config]),
        hasPolicy(PolicyID, "prohibited", [ImageMatcher|ProhibitedKeys]),
        matchImage(Image, ImageMatcher),
        anyPropPresent(ProhibitedKeys, Config).

    denyCtnByProhibitedKeys(Pod, [_|Rest], PolicyID) :-
      denyCtnByProhibitedKeys(Pod, Rest, PolicyID).

    // Latte-K8s only logic.
    authPodToUser(Pod, User) :-
      hasConfig(Pod, "latte.user", User).

    authPodToUser(Pod, User) :-
      hasConfig(Pod, "latte.creator", Creator),
      authPodToUser(Creator, User).

    authPodForLabel(Pod, Label, Expected) :-
      hasConfig(Pod, Label, Expected).

}.

definit consLibraryRules().

defcon consVMInstanceLocal(?Instance,?Image,?Vpc) :-
    ?VpcSet := label("vpc/?Vpc"),
{
    link($VpcSet).
    root("$IaaS").
    config($Instance,$PropertyVpcId, $Vpc).
    runs($Instance, $Image).
    label("instance/$Instance").
}.

defcon addNetAddr(?Instance,?NetAddr) :-
{
    bindToID($Instance, $NetAddr).
    label("instance/$Instance").
}.

defcon addCIDR(?Instance, ?CIDR) :-
{
    cidr($Instance, $CIDR).
    label("instance/$Instance").
}.


defcon dtorVMInstanceLocal(?Instance,?Image,?Vpc) :-
    ?VpcSet := label("vpc/?Vpc"),
{
    link($VpcSet).
    root("$IaaS")~
    config($Instance,$PropertyVpcId, $Vpc)~
    runs($Instance, $Image)~
    label("instance/$Instance").
    invalid(1).
}.

defcon delNetAddr(?Instance,?NetAddr) :-
{
    bindToID($Instance, $NetAddr)~
    label("instance/$Instance").
}.

defcon delCIDR(?Instance,?CIDR) :-
{
    cidr($Instance, $CIDR)~
    label("instance/$Instance").
}.

defpost postVMInstanceLocal(?Instance,?Image,?Vpc) :-
    [ consVMInstanceLocal(?Instance,?Image,?Vpc) ].
defpost delVMInstanceLocal(?Instance,?Image,?Vpc) :-
    [ dtorVMInstanceLocal(?Instance,?Image,?Vpc) ].

defpost postVMInstance(?Instance, ?Image, ?Vpc, ?NetAddr, ?CIDR) :-
    [ consVMInstanceLocal(?Instance, ?Image, ?Vpc),
      addNetAddr(?Instance, ?NetAddr),
      addCIDR(?Instance, ?CIDR)
    ].

defpost delVMInstance(?Instance, ?Image, ?Vpc, ?NetAddr, ?CIDR) :-
    [ dtorVMInstanceLocal(?Instance, ?Image, ?Vpc),
      delNetAddr(?Instance, ?NetAddr),
      delCIDR(?Instance, ?CIDR)
    ]. 

// Attestation of pods
defcon consInstanceLocal(?Instance,?Image) :-
    ?HostSet := label($BearerRef, "instance/$Self"),
{
    link($HostSet).
    runs($Instance, $Image).
    label("instance/$Instance").
}.

defcon dtorInstanceLocal(?Instance,?Image) :-
    ?HostSet := label($BearerRef, "instance/$Self"),
{
    link($HostSet).
    runs($Instance, $Image)~
    label("instance/$Instance").
    invalid(1).
}.

defpost postInstanceLocal(?Instance,?Image) :-
    [ consInstanceLocal(?Instance,?Image) ].
defpost delInstanceLocal(?Instance,?Image) :-
    [ dtorInstanceLocal(?Instance,?Image) ].

defpost postInstance(?Instance, ?Image, ?NetAddr) :-
   [ consInstanceLocal(?Instance, ?Image),
     addNetAddr(?Instance, ?NetAddr)
   ].

defpost delInstance(?Instance, ?Image, ?NetworkAddr) :-
   [  dtorInstanceLocal(?Instance, ?Image),
      delNetAddr(?Instance, ?NetAddr)
   ].

defcon consTrustedEndorserOn(?Endorser, ?Property, ?EndorsementLabel) :-
    ?TargetSet := label(?Endorser, ?EndorsementLabel),
{
    link($TargetSet).
    trustedEndorserOn($Property, $Endorser).
    label("trustedEndorsers").
}.

defcon dtorTrustedEndorserOn(?Endorser, ?Property, ?EndorsementLabel) :-
    ?TargetSet := label(?Endorser, ?EndorsementLabel),
{
    link($TargetSet).
    label("trustedEndorsers").
    trustedEndorserOn($Property, $Endorser)~
    invalid(1).
}.

defpost postTrustedEndorser(?Target, ?Property) :-
    [ consTrustedEndorserOn(?Target, ?Property, "trusthub") ].
defpost delTrustedEndorser(?Target, ?Property) :-
    [ dtorTrustedEndorserOn(?Target, ?Property, "trusthub") ].


defpost postAndDLinkTrustedEndorser(?Target, ?Property, ?EndorsementLabel) :-
    [ consTrustedEndorserOn(?Target, ?Property, ?EndorsementLabel) ].
defpost delAndDULinkTrustedEndorser(?Target, ?Property, ?EndorsementLabel) :-
    [ dtorTrustedEndorserOn(?Target, ?Property, ?EndorsementLabel) ].


defcon consEndorsementLink(?Target) :-
    ?TargetSet := label("endorsements/?Target"),
{
    link($TargetSet).
    label("trusthub").
}.

defcon dtorEndorsementLink(?Target) :-
  ?TargetSet := label("endorsements/?Target"),
{
    link($TargetSet)~
    label("trusthub").
    invalid(1).
}.

defpost postEndorsementLink(?Target) :-
    [ consEndorsementLink(?Target) ].
defpost delEndorsementLink(?Target) :-
    [ dtorEndorsementLink(?Target) ].


defcon consEndorsement(?Target,?Prop,?Value) :-
{
    endorse($Target, $Prop, $Value).
    label("endorsements/$Target").
}.

defcon dtorEndorsement(?Target,?Prop,?Value) :-
{
    endorse($Target, $Prop, $Value)~
    label("endorsements/$Target").
    invalid(1).
}.

defpost postEndorsement(?Target,?Prop,?Value) :-
    [ consEndorsement(?Target,?Prop,?Value) ].
defpost delEndorsement(?Target,?Prop,?Value) :-
    [ dtorEndorsement(?Target,?Prop,?Value) ].



defcon consInstanceConfigList(?Instance,?Config,?Value) :-
{
    config($Instance, $Config, $Value).
    label("instance/$Instance").
}.

defcon dtorInstanceConfigList(?Instance,?Config,?Value) :-
{
    config($Instance, $Config, $Value)~
    label("instance/$Instance").
    invalid().
}.

defpost postInstanceConfigList(?Instance,?Config,?Value) :-
    [ consInstanceConfigList(?Instance,?Config,?Value) ].
defpost delInstanceConfigList(?Instance,?Config,?Value) :-
    [ dtorInstanceConfigList(?Instance,?Config,?Value) ].

defguard checkProperty(?Instance,?Name,?Value) :- 
    ?InstanceSet := label($BearerRef, "instance/?Instance"),
    ?TrustWallet := label("trustWallet"),
    ?TrustedEndorserSet := label("trustedEndorsers"),
    ?LibraryRules := label("LKubeLibraryRules"),
{
    link($InstanceSet).
    link($TrustedEndorserSet).
    link($TrustWallet).
    link($LibraryRules).
    hasProperty($Instance, $Name, $Value)?
}.


defguard checkLaunches(?Instance,?Name) :- 
    ?InstanceSet := label($BearerRef, "instance/?Instance"),
    ?TrustWallet := label("trustWallet"),
    ?TrustedEndorserSet := label("trustedEndorsers"),
    ?LibraryRules := label("LKubeLibraryRules"),
{
    link($InstanceSet).
    link($TrustedEndorserSet).
    link($TrustWallet).
    link($LibraryRules).
    launches($Instance, $Name)?
}.


defguard checkHasConfig(?Instance,?Name,?Value) :- 
  ?InstanceSet := label($BearerRef, "instance/?Instance"),
  ?TrustWallet := label("trustWallet"),
  ?TrustedEndorserSet := label("trustedEndorsers"),
  ?LibraryRules := label("LKubeLibraryRules"),
  {
    link($InstanceSet).
    link($TrustedEndorserSet).
    link($TrustWallet).
    link($LibraryRules).
    hasConfig($Instance, $Name, $Value)?
  }.

defguard checkTrustedEndorser(?Endorser, ?PropName) :-
    ?TrustedEndorserSet := label("trustedEndorsers"),
{
    link($TrustedEndorserSet).
    trustedEndorserOn($PropName, $Endorser)?
}.


defguard checkAttester(?Instance) :- 
    ?InstanceSet := label($BearerRef, "instance/?Instance"),
    ?TrustWallet := label("trustWallet"),
    ?TrustedEndorserSet := label("trustedEndorsers"),
    ?LibraryRules := label("LKubeLibraryRules"),
{
    link($InstanceSet).
    link($TrustedEndorserSet).
    link($TrustWallet).
    link($LibraryRules).
    attester($Instance)?
}.


defguard checkPodAttestationLocal(?Instance) :-
    ?InstanceSet := label($BearerRef, "instance/?Instance"),
    ?TrustWallet := label("trustWallet"),
    ?TrustedEndorserSet := label("trustedEndorsers"),
    ?LibraryRules := label("LKubeLibraryRules"),
    ?ListRules := listMatchingRules(),
    ?Spec := label("endorsements/trustPolicy/default"),
    ?PolicyRules := label("trustPolicyRules"),
{
    link($InstanceSet).
    link($TrustedEndorserSet).
    link($TrustWallet).
    link($LibraryRules).
    link($ListRules).
    link($Spec).
    link($PolicyRules).
    approvePodByPolicy($Instance, default)? =@= require
    denyPodByPolicy($Instance, default)? =@= deny
}.


defguard checkPodAttestation(?Instance, ?PolicyID) :-
    ?InstanceSet := label($BearerRef, "instance/?Instance"),
    ?TrustWallet := label("trustWallet"),
    ?TrustedEndorserSet := label("trustedEndorsers"),
    ?LibraryRules := label("LKubeLibraryRules"),
    ?ListRules := listMatchingRules(),
    ?Spec := label("endorsements/trustPolicy/?PolicyID"),
    ?PolicyRules := label("trustPolicyRules"),
{
    link($InstanceSet).
    link($TrustedEndorserSet).
    link($TrustWallet).
    link($LibraryRules).
    link($ListRules).
    link($Spec).
    link($PolicyRules).
    approvePodByPolicy($Instance, $PolicyID)? =@= require
    denyPodByPolicy($Instance, $PolicyID)? =@= deny
}.

defguard checkPodByPolicy(?Instance, ?Policy) :-
    ?InstanceSet := label($BearerRef, "instance/?Instance"),
    ?TrustWallet := label("trustWallet"),
    ?TrustedEndorserSet := label("trustedEndorsers"),
    ?LibraryRules := label("LKubeLibraryRules"),
    ?ListRules := listMatchingRules(),
    ?PolicyRules := label("trustPolicyRules"),
{
    link($InstanceSet).
    link($TrustedEndorserSet).
    link($TrustWallet).
    link($LibraryRules).
    link($ListRules).
    link($PolicyRules).
    approvePodByPolicy($Instance, $Policy)? =@= require
    denyPodByPolicy($Instance, $Policy)? =@= deny
}.


defguard checkPodAccess(?Instance, ?Tag) :-
    ?TRoot := rootPrincipal(?Tag),
    ?TagSet := label(?TRoot, "groups/?Tag"),
    ?InstanceSet := label($BearerRef, "instance/?Instance"),
    ?TrustHub := label(?TRoot, "trusthub"),
    ?TrustWallet := label(?TRoot, "trustWallet"),
    ?TrustedEndorserSet := label(?TRoot, "trustedEndorsers"),
    ?LibraryRules := label("LKubeLibraryRules"),
    ?ListRules := listMatchingRules(),
    ?PolicyRules := label("trustPolicyRules"),
    ?MembershipPolicy := label("standard-membership-policy"),
{
    link($TagSet).
    link($InstanceSet).
    link($TrustHub).
    link($TrustWallet).
    link($TrustedEndorserSet).
    link($LibraryRules).
    link($ListRules).
    link($PolicyRules).
    link($MembershipPolicy).
    attester(P) :- $TRoot: attester(P).
    trustedCloudProvider(P) :- $TRoot: trustedCloudProvider(P).
    trustedEndorserOn(Property, E) :- $TRoot: trustedEndorserOn(Property, E).
    trustedEndorserOn(_, $TRoot).
    checkPodOnTag($Instance, $Tag)?
}.


defguard checkPodOwner(?Instance, ?Owner) :-
    ?InstanceSet := label($BearerRef, "instance/?Instance"),
    ?TrustWallet := label("trustWallet"),
    ?TrustedEndorserSet := label(?Owner, "trustedEndorsers"),
    ?LibraryRules := label("LKubelibraryRules"),
    ?PolicyRules := label("trustPolicyRules"),
{
    link($InstanceSet).
    link($TrustedEndorserSet).
    link($TrustWallet).
    link($LibraryRules).
    link($PolicyRules).
    authPodToUser($Instance, $Owner)?
}.

defguard checkPodLabel(?Instance, ?Label, ?Expected) :-
    ?InstanceSet := label($BearerRef, "instance/?Instance"),
    ?TrustWallet := label("trustWallet"),
    ?TrustedEndorserSet := label(?Owner, "trustedEndorsers"),
    ?LibraryRules := label("LKubeLibraryRules"),
    ?PolicyRules := label("trustPolicyRules"),
{
     link($InstanceSet).
     link($TrustedEndorserSet).
     link($TrustWallet).
     link($LibraryRules).
     link($PolicyRules).
     authPodForLabel($Instance, $Label, $Expected)?
}.

defguard debugCheck1(?Instance, ?Policy) :-
    ?InstanceSet := label($BearerRef, "instance/?Instance"),
    ?TrustWallet := label("trustWallet"),
    ?TrustedEndorserSet := label("trustedEndorsers"),
    ?LibraryRules := label("LKubeLibraryRules"),
    ?ListRules := listMatchingRules(),
    ?PolicyRules := label("trustPolicyRules"),
{
    link($InstanceSet).
    link($TrustedEndorserSet).
    link($TrustWallet).
    link($LibraryRules).
    link($ListRules).
    link($PolicyRules).
    approvePodByPolicy($Instance, $Policy)? =@= require
}.

defguard debugCheck2(?Instance, ?Policy) :-
    ?InstanceSet := label($BearerRef, "instance/?Instance"),
    ?TrustWallet := label("trustWallet"),
    ?TrustedEndorserSet := label("trustedEndorsers"),
    ?LibraryRules := label("LKubeLibraryRules"),
    ?ListRules := listMatchingRules(),
    ?PolicyRules := label("trustPolicyRules"),
{
    link($InstanceSet).
    link($TrustedEndorserSet).
    link($TrustWallet).
    link($LibraryRules).
    link($ListRules).
    link($PolicyRules).
    denyPodByPolicy($Instance, $Policy)? =@= deny
}.

defguard debugCheck3(?Instance, ?Policy, ?Containers) :-
    ?InstanceSet := label($BearerRef, "instance/?Instance"),
    ?TrustWallet := label("trustWallet"),
    ?TrustedEndorserSet := label("trustedEndorsers"),
    ?LibraryRules := label("LKubeLibraryRules"),
    ?ListRules := listMatchingRules(),
    ?PolicyRules := label("trustPolicyRules"),
{
    link($InstanceSet).
    link($TrustedEndorserSet).
    link($TrustWallet).
    link($LibraryRules).
    link($ListRules).
    link($PolicyRules).
    denyCtnByProhibitedKeys($Instance, $Containers, $Policy)? =@=deny
}.

defguard debugCheck4(?Image, ?ImageList) :-
    ?TrustWallet := label("trustWallet"),
    ?TrustedEndorserSet := label("trustedEndorsers"),
    ?LibraryRules := label("LKubeLibraryRules"),
    ?ListRules := listMatchingRules(),
{
    link($TrustedEndorserSet).
    link($TrustWallet).
    link($LibraryRules).
    link($ListRules).
    approveImage($Image, $ImageList)?
}.