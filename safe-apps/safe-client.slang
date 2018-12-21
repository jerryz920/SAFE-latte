defcall postRawIdSet(?CN) :-
  {
    postRawIdSet($ServerJVM, $ReqEnvs, $CN).
  }.

defcall postIdSet(?CN, ?StoreAddr, ?Protocol, ?ServerID) :-
  {
    postIdSet($ServerJVM, $ReqEnvs, $CN, $StoreAddr, $Protocol, $ServerID).
  }.

defcall updateIDSet(?StoreAddr, ?Protocol, ?ServerID) :-
  {
     updateIDSet($ServerJVM, $ReqEnvs, $StoreAddr, $Protocol, $ServerID).
  }.

defcall postSubjectSet() :-
  {
    postSubjectSet($ServerJVM, $ReqEnvs).
  }.

defcall updateSubjectSet(?Token) :-
  {
    updateSubjectSet($ServerJVM, $ReqEnvs, $Token).
  }.

defcall serverImport(?SlangPathname) :-
  {
    import($ServerJVM, $ReqEnvs, $SlangPathname).
  }.
