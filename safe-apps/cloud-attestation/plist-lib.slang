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

defcon addFilePropertySpec(?File, ?Policy, ?Prohibited, ?Qualifiers, ?Required) :-
{
    specProhibited($File, $Policy, $Prohibited).
    specQualifiers($File, $Policy, $Qualifiers).
    specRequired($File, $Policy, $Required).
    label("specification/$File/$Policy").
}.
defpost postPropertySpec(?Prohibited, ?Qualifiers, ?Required) :-
  [addPropertySpec(?Prohibited, ?Qualifiers, ?Required)].

defpost postFilePropertySpec(?File, ?Policy, ?Prohibited, ?Qualifiers, ?Required) :-
  [addPropertySpec(?File, ?Policy, ?Prohibited, ?Qualifiers, ?Required)].

defcon addImageSpec(?ImageList) :-
{
    specImages($ImageList).
    label("specification").
}.

defcon addFileImageSpec(?File, ?Policy, ?ImageList) :-
{
    specImages($File, $Policy, $ImageList).
    label("specification/$File/$Policy").
}.

defpost postImageSpec(?Image) :-
  [addImageSpec(?Image)].

defpost postFileImageSpec(?File, ?Policy, ?Image) :-
  [addFileImageSpec(?File, ?Policy, ?Image)].

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

defguard checkSubSeq(?Spec, ?Config) :-
  ?ListRules := listMatchingRules(),
  ?PropertyPolicy := label("std-property-policy"),
{
  link($ListRules).
  link($PropertyPolicy).
  esubseq($Spec, $Config)?
}.

defguard checkPresent(?Spec, ?Config) :-
  ?ListRules := listMatchingRules(),
  ?PropertyPolicy := label("std-property-policy"),
{
  link($ListRules).
  link($PropertyPolicy).
  propsPresent($Spec, $Config)?
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

// Test if L is an extended subsequence of R.
esubseq([[X,Y]|L], [[X,Y]|R]) :-
   esubseq(L, R).
esubseq([[H,Y]|L], [[S,_]|R]) :-
   S < H,
   esubseq([[H,Y]|L], R).
esubseq([], R).

// Test if L and R intersect
intersecting([E|_], [E|_]).
intersecting([S|L], R) :-
  [H|_] = R,
  S < H,
  intersecting(L, R).
intersecting(L, [S|R]) :-
  [H|_] = L,
  S < H,
  intersecting(L, R).

// Test if L is a extended subsequence of any element in right hand side
//esubseq([], R).
//esubseq([Head|_], R) :-
//   esubseq(Head, R).
//esubseq([_|Rest], R) :-
//   esubseq(Rest, R).

// Test if each property K in L corresponds to a [K,V] pair in R.
propsPresent([], R).
propsPresent([K|L], [[K,_]|R]):-
  propsPresent(L, R).
propsPresent(L, [[S,_]|R]):-
  [H|_] = L,
  S < H,
  propsPresent(L, R).

//propsPresent([Head|_], R) :-
//  propsPresent(Head, R).
//propsPresent([_|Rest], R) :-
//  propsPresent(Rest, R).

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

//anyPropPresent([Head | _], R) :-
//  anyPropPresent(Head, R).
//
//anyPropPresent([_| Rest], R) :-
//  anyPropPresent(Rest, R).


  label("property-list-rules").
}.
