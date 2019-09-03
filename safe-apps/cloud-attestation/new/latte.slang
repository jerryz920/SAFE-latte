import("../plist-lib.slang").

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
      specQualifier(Spec),
      subseq(Spec, Config).
      approveCtnByQualifier(Pod, Rest).

    approveCtnByRequired(Pod, [Ctn|Rest]) :-
      hasConfig(Pod, Ctn, [_|Config]),
      specRequired(Spec),
      propsPresent(Spec, Config),
      approveCtnByRequired(Rest).

    denyCtnByProhibited(Pod, [Ctn|Rest]) :-
      hasConfig(Pod, Ctn, [_|Config]),
      specProhibited(Spec),
      anyPropPresent(Spec, Config),
      denyCtnByProhibited(Rest).

    approveCtnByImage(Pod, [Ctn|Rest]) :-
      hasConfig(Pod, Ctn, [Image|_]),
      specImage(Spec),
      subseq(Spec, Image),
      approveCtnByImage(Pod, Rest).

    approveCtnByQualifier(Pod, []).
    approveCtnByRequired(Pod, []).
    approveCtnByPresent(Pod, []).
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
  approvePodByImage($Instance)? =@= allow
  approvePodByQualifier($Instance)? =@= allow
  approvePodByRequired($Instance)? =@= allow
  denyPodByProhibited($Instance)? =@= deny
}.
