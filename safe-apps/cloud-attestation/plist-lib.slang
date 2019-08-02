import("../safe.slang").

defcon launchInstance(?PID, ?Image, ?NetAddr, ?Config) :-
  ?ImgSet := label($IaaS, "vm-image/?Image"),
  ?AttesterSet := label($Self, "subject($Self)"),
  // ?IP := ipFromNetworkID(?NetAddr),
  // ?Port := portFromNetworkID(?NetAddr),
{
    link($ImgSet).
    link($AttesterSet).
    runs($PID, $Image).
    bindToID($PID, $NetAddr).
    config($PID, $Config).
    label("instance/$PID").  // update this link to instance subject set
}.

defpost postInstanceSet(?PID, ?Image, ?NetAddr, ?Config) :-
  [launchInstance(?PID, ?Image, ?NetAddr, ?Config)].

defcon addPropertySpec(?Prohibited, ?Qualifiers, ?Required) :-
{
    specProhibited($Prohibited).
    specQualifiers($Qualifiers).
    specRequired($Required).
    label("specification").
}.

defpost postPropertySpec(?Prohibited, ?Qualifiers, ?Required) :-
  [addPropertySpec(?Prohibited, ?Qualifiers, ?Required)].

defguard verifyAttestation(?PID) :-
  ?ListRules := listMatchingRules(),
  ?Attestation := label("instance/?PID"),
  ?PropertyPolicy := label("std-property-policy"),
  ?Spec := label("specification"),
{
  link($ListRules).
  link($Attestation).
  link($PropertyPolicy).
  link($Spec).
  approveByQualifiers($PID)? =@= allow
  approveByRequired($PID)? =@= allow
  denyByProhibited($PID)? =@= deny
}.

defcon propertyListPolicy() :-
{
  approveByQualifiers(PID) :-
    config(PID, Config),
    specQualifiers(Spec),
    subseq(Spec, Config).

  approveByRequired(PID) :-
    config(PID, Config),
    specRequired(Spec),
    propsPresent(Spec, Config).

  denyByProhibited(PID) :-
    config(PID, Config),
    specProhibited(Spec),
    anyPropPresent(Spec, Config).

  label("std-property-policy").
}.


defcon listMatchingRules() :-
{
// Test if L is a subsequence of R.
subseq([X|L], [X|R]) :-
   subseq(L, R).
subseq([H|L], [S|R]) :-
   S < H,
   subseq([H|L], R).
subseq([], R).

// Test if each property K in L corresponds to a [K,V] pair in R.
propsPresent([], R).
propsPresent([K|L], [[K,_]|R]):-
  propsPresent(L, R).
propsPresent(L, [[S,_]|R]):-
  [H|_] = L,
  S < H,
  propsPresent(L, R).

// Test if any property K in L corresponds to a [K,V] pair in R.
anyPropPresent([K|_],[[K,_]|_]).
anyPropPresent(L, [[S,_]|R]) :-
  [H|_] = L,
  S < H,
  anyPropPresent(L,R).
anyPropPresent([S|L], R) :-
  [[H,_]|_] = R,
  S < H,
  anyPropPresent(L,R).

  label("property-list-rules").
}.