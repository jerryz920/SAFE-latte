% Designed to operate on sorted lists.
% Set libraryOn in application conf when launching styla shell.
% It deals with string key values.

% Is L a subsequence of R.
subseq([X|L], [X|R]) :-
   subseq(L, R).

subseq([H|L], [S|R]) :-
   S < H,
   subseq([H|L], R).
%subseq(L, [S|R]) :-
%   [H|_] = L,
%   traceln(H),
%   S < H,
%   subseq(L, R).

subseq([], R).
%subseq(L, R) :- L = [].
%subseq(L, R) :- eq(L, []).

% Queries:
% subseq([1,3], [0,1,2,3,4,5]).
% subseq(["alice", "bob", "cindy"], ["alice", "bob", "cindy", "david", "frank", "george"]).

% Is for each property K in L there one corresponding [K,V] pair in R.
propsPresent([], R).
propsPresent([K|L], [[K,_]|R]):-      
  propsPresent(L, R).
propsPresent(L, [[S,_]|R]):-
  [H|_] = L,
  S < H,
  propsPresent(L, R).

% Queries
% propsPresent([1,3,4], [[1, "alice"], [2, "bob"], [3, "cindy"], [4, "david"], [5, "frank"]).
% propsPresent(["port", "protocol"], [["master_addr", "152.3.136.112"], ["port", 10009], ["protocol", "http"]]). 

% Does any property K in L have a corresponding [K,V] pair in R.
anyPropPresent([K|_],[[K,_]|_]).
anyPropPresent(L, [[S,_]|R]) :-
  [H|_] = L,
  S < H,
  anyPropPresent(L,R).
anyPropPresent([S|L], R) :-
  [[H,_]|_] = R,
  S < H,
  anyPropPresent(L,R).

% Queries
% anyPropPresent([1, 2], [[2, "bob"], [3, "cindy"]]).
% anyPropPresent(["policy_dir", "port"], [["master_addr", "152.3.136.112"], ["port", 10009], ["protocol", "http"]]).
