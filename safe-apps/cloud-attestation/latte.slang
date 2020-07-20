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

    launches(H, Instance, Image) :-
        H: runs(Instance, Image),
        attester(H).

    launch(Instance, Image) :-
        H : runs(Instance, Image),
        attester(H).

    builder(Instance) :-
        hasProperty(Instance, 'builder', 1).

    launch(Instance, Program) :-
        B: builtInto(Program, Image),
        launch(Instance, Image),
        builder(B).

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
        launch(Instance, Image),
        hasProperty(Image, Property, Value).

//    hasProperty(Instance, Property, PolicyID) :-
//        hasPolicy(PolicyID, "podProperty", Property),
//        checkCompliance(Instance, PolicyID).

    checkPodOnTag(Instance, Tag) :-
        authPodToUser(Instance, User),
        membership(Tag, User).

    checkPodOnTag(Instance, Tag) :-
        membership(Tag, Instance).

    checkCompliance(Instance, ConfigSet, H) :-
        approvePodByPolicy(Instance, ConfigSet, H),
        \+( denyPodByPolicy(Instance, ConfigSet, H) ).

    // Approve a pod by checking it against a whitelist of images,
    // a list of qualifier config KV pairs, a list of required config
    // keys specified by a policy (which is identified by a configset ID).
    approvePodByPolicy(Pod, ConfigSet, H) :- 
        H: config(Pod, 'containers', Containers),
        approveCtnByImagePolicy(Pod, Containers, ConfigSet, H),
        approveCtnByQualifiedKvs(Pod, Containers, ConfigSet, H),
        approveCtnByRequiredKeys(Pod, Containers, ConfigSet, H).

    /// Image handling
    approveCtnByImagePolicy(Pod, [Ctn|Rest], ConfigSet, H) :-
        H: config(Pod, Ctn, [Image|_]),
        hasPolicy(ConfigSet, "image", WhiteListImages),
        approveImage(Image, WhiteListImages),
        approveCtnByImagePolicy(Pod, Rest, ConfigSet, H).

    /// Image matching polices
    matchImage(Image, Matcher) :-
        hasProperty(Image, Prop, 1).

    // Allow wildcard
    matchImage(_, any).

    matchImage(Image, Image).

    approveCtnByImagePolicy(_, [], _, _).

    // Handle image: whitelist, or an endorsed property
    approveImage(Image, [Prop|_]) :-
        matchImage(Image, Prop).

    approveImage(Image, [_|Rest]) :-
        approveImage(Image, Rest).

    // Handle Required Keys and QualifiedKvs
    approveCtnByQualifiedKvs(Pod, [Ctn|Rest], ConfigSet, H) :-
        H: config(Pod, Ctn, [Image|Config]),
        hasPolicy(ConfigSet, "qualifier", [ImageMatcher|QualifiedKvs]),
        matchImage(Image, ImageMatcher),
        esubseq(QualifiedKvs, Config),
        approveCtnByQualifiedKvs(Pod, Rest, ConfigSet, H).

    approveCtnByQualifiedKvs(_, [], _, _).

    approveCtnByRequiredKeys(Pod, [Ctn|Rest], ConfigSet, H) :-
        H:config(Pod, Ctn, [Image|Config]),
        hasPolicy(ConfigSet, "required", [ImageMatcher|RequiredKeys]),
        matchImage(Image, ImageMatcher),
        propsPresent(RequiredKeys, Config),
        approveCtnByRequiredKeys(Pod, Rest, ConfigSet, H).

    approveCtnByRequiredKeys(_, [], _, _).


    // Deny check on a pod's config against a policy
    denyPodByPolicy(Pod, ConfigSet, H) :-
        H: config(Pod, 'containers', Containers),
        denyCtnByProhibitedKeys(Pod, Containers, ConfigSet, H).

    denyCtnByProhibitedKeys(Pod, [Ctn|_], ConfigSet, H) :-
        H: config(Pod, Ctn, [Image|Config]),
        hasPolicy(ConfigSet, "prohibited", [ImageMatcher|ProhibitedKeys]),
        matchImage(Image, ImageMatcher),
        anyPropPresent(ProhibitedKeys, Config).

    denyCtnByProhibitedKeys(Pod, [_|Rest], ConfigSet, H) :-
      denyCtnByProhibitedKeys(Pod, Rest, ConfigSet, H).

    // Latte-K8s only logic
    authPodToUser(Pod, User) :-
      hasConfig(Pod, "global", Gconfig),
      esubseq(["latte.user", User], Gconfig).

    // authPodToUser(Pod, User) :-
    //   hasConfig(Pod, "latte.user", User).

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
    launch($Instance, $Name)?
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
    approvePodByPolicy($Instance, default, $BearerRef)? =@= require
    denyPodByPolicy($Instance, default, $BearerRef)? =@= deny
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
    approvePodByPolicy($Instance, $PolicyID, $BearerRef)? =@= require
    denyPodByPolicy($Instance, $PolicyID, $BearerRef)? =@= deny
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
    approvePodByPolicy($Instance, $Policy, $BearerRef)? =@= require
    denyPodByPolicy($Instance, $Policy, $BearerRef)? =@= deny
}.

defguard checkWorker(?Instance, ?Tag) :- checkPodAccess(?Instance, ?Tag).

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
    trustedCloudProvider($IaaS).
    attester(P) :- $TRoot: attester(P).
    trustedCloudProvider(P) :- $TRoot: trustedCloudProvider(P).
    trustedEndorserOn(Property, E) :- $TRoot: trustedEndorserOn(Property, E).
    trustedEndorserOn(_, $TRoot).
    checkPodOnTag($Instance, $Tag)?
}.

defguard checkDriverGroup(?Instance, ?Creator, ?PolicyID) :-
    ?DriverGroup := "?Creator:?Instance",
    ?GroupSet := label(?Creator, "groups/?DriverGroup"),
    ?InstanceSet := label($BearerRef, "instance/?Instance"),
    ?CheckingPolicy := label("endorsements/trustPolicy/?PolicyID"),
    ?TrustedEndorserSet := label("trustedEndorsers"),
    ?LibraryRules := label("LKubeLibraryRules"),
    ?ListRules := listMatchingRules(),
    ?PolicyRules := label("trustPolicyRules"),
{
    link($GroupSet).
    link($InstanceSet).
    link($CheckingPolicy).
    link($TrustedEndorserSet).
    link($LibraryRules).
    link($ListRules).
    link($PolicyRules).

    approveDriverGroup($DriverGroup, $PolicyID)?
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
    approvePodByPolicy($Instance, $Policy, $BearerRef)? =@= require
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
    denyPodByPolicy($Instance, $Policy, $BearerRef)? =@= deny
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
    denyCtnByProhibitedKeys($Instance, $Containers, $Policy, $BearerRef)? =@=deny
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