
//////////////////////////////////////////////////////
// Enviroments
//////////////////////////////////////////////////////
// Envs from Latte default
defenv IaaS() :- "152.3.145.38:444".
defenv PropertyAttester() :- "attester".

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

    hasProperty(Obj, Property, Value) :-
      H: endorse(Obj, Property, Value).
      trustedEndorserOn(Property, H).

    hasProperty(Instance, Property, Value) :-
      launches(Instance, Image),
      hasProperty(Image, Property, Value).

  }.

definit consLibraryRules().


defcon consTrustedEndorserOn(?Endorser, ?Property) :-
  ?TargetSet := label(?Endorser, "trusthub"),
  {
    link($TargetSet).
    trustedEndorserOn($Property, $Endorser).
    label("trustedEndorsers").
  }.

defpost postTrustedEndorser(?Target, ?Property) :- [ consTrustedEndorserOn(?Target, ?Property) ].

defcon consEndorsementLink(?Target) :-
  ?TargetSet := label("endorsements/?Target"),
  {
    link($TargetSet).
    label("trusthub").
  }.

defpost postEndorsementLink(?Target) :- [ consEndorsementLink(?Target) ].


defcon consEndorsement(?Target,?Prop,?Value) :-
  {
    endorse($Target, $Prop, $Value).
    label("endorsements/$Target").
  }.

defpost postEndorsement(?Target,?Prop,?Value) :- [ consEndorsement(?Target,?Prop,?Value) ].


defguard checkProperty(?Instance, ?Name, ?Value) :- 
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
