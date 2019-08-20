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


    // K8s specific guard rule, how to?
    //
    // approvePod(Pod) :-
    //   approvePodGlobalConfig(Pod),
    //   approvePodContainerConfigs(Pod),
    //
    // approvePodGlobalConfig(Pod) :-
    //   hasConfig(Pod, 'global', GlobalKVList),
    //   ??? (need a specific policy on GlobalKVList).
    //
    // approvePodContainerConfigs(Pod).
    //   hasConfig(Pod, 'containers', ContainerList),
    //   \+ ( // check all image has someproperty
    //     ??? (Ctn in ContainerList), Ctn is overloaded
    //     hasConfig(Ctn, 'image', Image),
    //     \+hasProperty(Image, 'someproperty', 'somevalue).
    //   ),
    //   \+ ( // check all container has approved config
    //     ??? (Ctn in ContainerList),
    //     // each container's config is fetched by hasConfig(Ctn, 'config', ConfigKvs)
    //     ??? (run a policy on Ctn).
    //   ).
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

defpost postInstance(?Instance,?Image,?TrustHub) :- [ consInstance(?Instance,?Image,?TrustHub) ].
defpost delInstance(?Instance,?Image,?TrustHub) :- [ dtorInstance(?Instance,?Image,?TrustHub) ].


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



defcon consInstanceConfigList(?Instance,?Config) :-
{
  config($Instance, $Config).
  label("instance/$Instance").
}.

defcon dtorInstanceConfigList(?Instance,?Config,?Value) :-
{
  config($Instance, $Config, $Value)~
  label("instance/$Instance").
  invalid().
}.

defpost postInstanceConfigList(?Instance,?Config,?Value) :- [ consInstanceConfig(?Instance,?Config,?Value) ].
defpost delInstanceConfigList(?Instance,?Config,?Value) :- [ dtorInstanceConfig(?Instance,?Config,?Value) ].



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

