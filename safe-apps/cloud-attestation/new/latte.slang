import("../plist-lib.slang").
import("./policy.slang").

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
    label("libraryRules").

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



/// Pod specific rules

    approveCtnByQualifier(Pod, [Ctn|Rest]) :-
      hasConfig(Pod, Ctn, [_|Config]),
      specQualifiers(Spec),
      esubseq(Config, Spec),
      approveCtnByQualifier(Pod, Rest).

    approveCtnByRequired(Pod, [Ctn|Rest]) :-
      hasConfig(Pod, Ctn, [_|Config]),
      specRequired(Spec),
      propsPresent(Spec, Config),
      approveCtnByRequired(Pod, Rest).

    denyCtnByProhibited(Pod, [Ctn|_]) :-
      hasConfig(Pod, Ctn, [_|Config]),
      specProhibited(Spec),
      anyPropPresent(Spec, Config).

    denyCtnByProhibited(Pod, [_|Rest]) :-
      denyCtnByProhibited(Pod, Rest).

    approveCtnByImage(Pod, [Ctn|Rest]) :-
      hasConfig(Pod, Ctn, [Image|_]),
      specImages(Spec),
      subseq([Image], Spec),
      approveCtnByImage(Pod, Rest).

    approveCtnByQualifier(Pod, []).
    approveCtnByRequired(Pod, []).
    approveCtnByImage(Pod, []).


  approvePodByImage(Pod) :-
      hasConfig(Pod, 'containers', Containers),
      approveCtnByImage(Pod, Containers).

  approvePodByQualifier(Pod) :-
      hasConfig(Pod, 'containers', Containers),
      approveCtnByQualifier(Pod, Containers).

  approvePodByRequired(Pod) :-
      hasConfig(Pod, 'containers', Containers),
      approveCtnByRequired(Pod, Containers).

  denyPodByProhibited(Pod) :-
      hasConfig(Pod, 'containers', Containers),
      denyCtnByProhibited(Pod, Containers).

  //// Above approve and deny rules are just for references.

  // If Pod's image/required config key/qualified config kvs are approved by
  // given policy ID. We can not query if there is such a policy that can
  // approve the Pod at the moment.
  approvePodByRequiredPolicy(Pod, Policy) :- 
      policy(Policy, ImagePolicy, _, QualifiedKvs, RequiredKeys),
      hasConfig(Pod, 'containers', Containers),
      approveCtnByImagePolicy(Pod, Containers, ImagePolicy),
      approveCtnByQualifiedKvs(Pod, Containers, QualifiedKvs),
      approveCtnByRequiredKeys(Pod, Containers, RequiredKeys).
  
  /// Image handling
  approveCtnByImagePolicy(Pod, [Ctn|Rest], ImagePolicy) :-
      hasConfig(Pod, Ctn, [Image|_]),
      approveImage(Image, ImagePolicy),
      approveCtnByImage(Pod, Rest, ImagePolicy).

  approveCtnByImagePolicy(_, [], _).

  // Handle image: whitelist, or an endorsed property
  approveImage(Image, [Prop|_]) :-
      hasProperty(Image, Prop, 1).
  approveImage(Image, [Image|_]).

  approveImage(Image, [_|Rest]) :-
      approveImage(Image, Rest).

  // Handle Required Keys and QualifiedKvs
  approveCtnByQualifiedKvs(Pod, [Ctn|Rest], QualifiedKvs) :-
      hasConfig(Pod, Ctn, [_|Config]),
      esubseq(QualifiedKvs, Config),
      approveCtnByQualifiedKvs(Pod, Rest, QualifiedKvs).

  approveCtnByQualifiedKvs(_, [], _).

  approveCtnByRequiredKeys(Pod, [Ctn|Rest], RequiredKeys) :-
      hasConfig(Pod, Ctn, [_|Config]),
      propsPresent(RequiredKeys, Config),
      approveCtnByRequiredKeys(Pod, Rest, RequiredKeys).

  approveCtnByRequiredKeys(_, [], _).

  // Configuration Checks

  denyPodByProhibitedKeys(Pod, Policy) :-
      policy(Policy, _, ProhibitedKeys, _, _),
      hasConfig(Pod, 'containers', Containers),
      denyCtnByProhibitedKeys(Pod, Containers, ProhibitedKeys).

    denyCtnByProhibited(Pod, [Ctn|_], ProhibitedKeys) :-
      hasConfig(Pod, Ctn, [_|Config]),
      anyPropPresent(ProhibitedKeys, Config).

    denyCtnByProhibited(Pod, [_|Rest], ProhibitedKeys) :-
      denyCtnByProhibited(Pod, Rest, ProhibitedKeys).

  // Latte-K8s only logic.
  authPodToUser(Pod, User) :-
    hasConfig(Pod, "latte.user", User).

  authPodToUser(Pod, User) :-
    hasConfig(Pod, "latte.creator", Creator),
    authPodToUser(Creator, User).
  }.

definit consLibraryRules().

defcon consVMInstance(?Instance,?Image,?Vpc) :-
  ?VpcSet := label("vpc/?Vpc"),
  ?SelfSet := label($Self, "instance/?Instance"),
  {
    link($VpcSet).
    link($SelfSet).
    root("$IaaS").
    config($Instance,$PropertyVpcId, $Vpc).
    runs($Instance, $Image).
    label("instance/$Instance").
  }.

defcon dtorVMInstance(?Instance,?Image,?Vpc) :-
  ?VpcSet := label("vpc/?Vpc"),
  ?SelfSet := label($Self, "instance/$Self"),
  {
    link($VpcSet).
    link($SelfSet).
    root("$IaaS")~
    config($Instance,$PropertyVpcId, $Vpc)~
    runs($Instance, $Image)~
    label("instance/$Instance").
    invalid(1).
  }.

defpost postVMInstance(?Instance,?Image,?Vpc) :- [ consVMInstance(?Instance,?Image,?Vpc) ].
defpost delVMInstance(?Instance,?Image,?Vpc) :- [ dtorVMInstance(?Instance,?Image,?Vpc) ].

defcon consInstance(?Instance,?Image) :-
  ?HostSet := label($BearerRef, "instance/$Self"),
  ?SelfSet := label($Self, "instance/$Self"),
{
  link($HostSet).
    link($SelfSet).
    runs($Instance, $Image).
    label("instance/$Instance").
}.

defcon dtorInstance(?Instance,?Image) :-
?HostSet := label($BearerRef, "instance/$Self"),
  ?SelfSet := label($Self, "instance/$Self"),
{
  link($HostSet).
    link($SelfSet).
    runs($Instance, $Image)~
    label("instance/$Instance").
    invalid(1).
}.

defpost postInstance(?Instance,?Image) :- [ consInstance(?Instance,?Image) ].
defpost delInstance(?Instance,?Image) :- [ dtorInstance(?Instance,?Image) ].


defcon consTrustedEndorserOn(?Endorser, ?Property) :-
  ?TargetSet := label(?Endorser, "trusthub"),
  {
    link($TargetSet).
    trustedEndorserOn($Property, $Endorser).
    label("trustedEndorsers").
  }.

defcon dtorTrustedEndorserOn(?Endorser, ?Property) :-
  ?TargetSet := label(?Endorser, "trusthub"),
  {
    link($TargetSet).
    label("trustedEndorsers").
    trustedEndorserOn($Property, $Endorser)~
    invalid(1).
  }.

defpost postTrustedEndorser(?Target, ?Property) :- [ consTrustedEndorserOn(?Target, ?Property) ].
defpost delTrustedEndorser(?Target, ?Property) :- [ dtorTrustedEndorserOn(?Target, ?Property) ].


defcon consEndorsementLink(?Target) :-
  ?TargetSet := label("endorsements/?Target"),
  {
    link($TargetSet).
    label("trusthub").
  }.

defcon dtorEndorsementLink(?Target) :-
  ?TargetSet := label("endorsements/?Target"),
  {
    link($TargetSet).
    label("trusthub").
    invalid(1).
  }.

defpost postEndorsementLink(?Target) :- [ consEndorsementLink(?Target) ].
defpost delEndorsementLink(?Target) :- [ dtorEndorsementLink(?Target) ].


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

defpost postEndorsement(?Target,?Prop,?Value) :- [ consEndorsement(?Target,?Prop,?Value) ].
defpost delEndorsement(?Target,?Prop,?Value) :- [ dtorEndorsement(?Target,?Prop,?Value) ].



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

defpost postInstanceConfigList(?Instance,?Config,?Value) :- [ consInstanceConfigList(?Instance,?Config,?Value) ].
defpost delInstanceConfigList(?Instance,?Config,?Value) :- [ dtorInstanceConfigList(?Instance,?Config,?Value) ].





defguard checkProperty(?Instance,?Name,?Value) :- 
  ?InstanceSet := label($BearerRef, "instance/?Instance"),
  ?HostSet := label(?Instance, "instance/?Instance"),
  ?TrustWallet := label("trustWallet"),
  ?TrustedEndorserSet := label("trustedEndorsers"),
  ?LibraryRules := label("libraryRules"),
  {
    link($InstanceSet).
    link($HostSet).
    link($TrustedEndorserSet).
    link($TrustWallet).
    link($LibraryRules).
    hasProperty($Instance, $Name, $Value)?
  }.


defguard checkLaunches(?Instance,?Name) :- 
  ?InstanceSet := label($BearerRef, "instance/?Instance"),
  ?HostSet := label(?Instance, "instance/?Instance"),
  ?TrustWallet := label("trustWallet"),
  ?TrustedEndorserSet := label("trustedEndorsers"),
  ?LibraryRules := label("libraryRules"),
  {
    link($InstanceSet).
    link($HostSet).
    link($TrustedEndorserSet).
    link($TrustWallet).
    link($LibraryRules).
    launches($Instance, $Name)?
  }.


defguard checkHasConfig(?Instance,?Name,?Value) :- 
  ?InstanceSet := label($BearerRef, "instance/?Instance"),
  ?HostSet := label(?Instance, "instance/?Instance"),
  ?TrustWallet := label("trustWallet"),
  ?TrustedEndorserSet := label("trustedEndorsers"),
  ?LibraryRules := label("libraryRules"),
  {
    link($InstanceSet).
    link($HostSet).
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
  ?HostSet := label(?Instance, "instance/?Instance"),
  ?TrustWallet := label("trustWallet"),
  ?TrustedEndorserSet := label("trustedEndorsers"),
  ?LibraryRules := label("libraryRules"),
  {
    link($InstanceSet).
    link($HostSet).
    link($TrustedEndorserSet).
    link($TrustWallet).
    link($LibraryRules).
    attester($Instance)?
  }.


defguard checkPodAttestation(?Instance) :-
  ?InstanceSet := label($BearerRef, "instance/?Instance"),
  ?HostSet := label(?Instance, "instance/?Instance"),
  ?TrustWallet := label("trustWallet"),
  ?TrustedEndorserSet := label("trustedEndorsers"),
  ?LibraryRules := label("libraryRules"),
  ?ListRules := listMatchingRules(),
  ?Spec := label("specification"),
{
  link($InstanceSet).
  link($HostSet).
  link($TrustedEndorserSet).
  link($TrustWallet).
  link($LibraryRules).
  link($ListRules).
  link($Spec).
  approvePodByImage($Instance)? =@= require
  approvePodByQualifier($Instance)? =@= require
  approvePodByRequired($Instance)? =@= require
  denyPodByProhibited($Instance)? =@= deny
}.

// ?Owner is extracted from the file path...
defguard checkPodByPolicy(?Instance, ?Policy) :-
  ?InstanceSet := label($BearerRef, "instance/?Instance"),
  ?HostSet := label(?Instance, "instance/?Instance"),
  ?TrustWallet := label("trustWallet"),
  ?TrustedEndorserSet := label(?Owner, "trustedEndorsers"),
  ?LibraryRules := label("libraryRules"),
  ?ListRules := listMatchingRules(),
  {
  link($InstanceSet).
  link($HostSet).
  link($TrustedEndorserSet).
  link($TrustWallet).
  link($LibraryRules).
  link($ListRules).
  approvePodByRequiredPolicy($Instance, $Policy)? =@= require
  denyPodByProhibitedKeys($Instance, $Policy)? =@= deny
  }.

defguard checkPodOwner(?Instance, ?Owner) :-
  ?InstanceSet := label($BearerRef, "instance/?Instance"),
  ?HostSet := label(?Instance, "instance/?Instance"),
  ?TrustWallet := label("trustWallet"),
  ?TrustedEndorserSet := label(?Owner, "trustedEndorsers"),
  ?LibraryRules := label("libraryRules"),
   {
     link($InstanceSet).
       link($HostSet).
       link($TrustedEndorserSet).
       link($TrustWallet).
       link($LibraryRules).
       authPodToUser($Instance, $Owner)?
   }



