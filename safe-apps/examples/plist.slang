import("../safe.slang").
// import("safe-apps/examples/plist.slang").

defguard subseq(?L,?R) :-
  ?Rules := therules(),
{
  link(?Rules).
  subseq(?L,?R)?
}.

defguard propsPresent(?L,?R) :-
  ?Rules := therules(),
{
  link($Rules).
  propsPresent($L,$R)?
}.

defguard anyPropPresent(?L,?R) :-
  ?Rules := therules(),
{
  link($Rules).
  anyPropPresent($L,$R)?
}.


defcon therules() :-
{
// Is L a subsequence of R.
subseq([X|L], [X|R]) :-
   subseq(L, R).
subseq(L, [_|R]) :-
   subseq(L, R).
subseq([], []).

// Does each property K in L have one corresponding [K,V] pair in R.
propsPresent([], []).
propsPresent([K|L], [[?K,_]|R]):-      
  propsPresent(L, R).
propsPresent(L, [_|R]):-
  propsPresent(L, R).

// Does any property K in L have a corresponding [K,V] pair in R.
anyPropPresent([K|_],[[K,_]|_]).
anyPropPresent([_|L],R) :-
  anyPropPresent(L,R).

  label("therules").
}.
