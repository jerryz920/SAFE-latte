defcall postIdSetRaw(?CN) :-
  {
    postIdSet($ServerJVM, $Envs, $CN).
  }.

defcall postIdSet(?CN, ?StoreAddr, ?Protocol, ?ServerID) :-
  {
    postIdSet($ServerJVM, $Envs, $CN, $StoreAddr, $Protocol, $ServerID).
  }.

defcall updateIDSet(?StoreAddr, ?Protocol, ?ServerID) :-
  {
     updateIDSet($ServerJVM, $Envs, $StoreAddr, $Protocol, $ServerID).
  }.

defcall postSubjectSet() :-
  {
    postSubjectSet($ServerJVM, $Envs).
  }.

defcall updateSubjectSet(?Token) :-
  {
    updateSubjectSet($ServerJVM, $Envs, $Token).
  }.

defcall serverImport(?SlangPathname) :-
  {
    import($ServerJVM, $Envs, $SlangPathname).
  }.
