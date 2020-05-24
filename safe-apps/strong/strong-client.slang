import("../safe-client.slang").

defenv ServerJVM() :- "152.3.136.26:6666".
defenv ReqEnvs() :- ":::".
defenv Self() :- "strong-1".

defcall postGroupMember(?GroupId, ?SubjectId, ?Delegatable) :-
  {
    postGroupMember($ServerJVM, $ReqEnvs, $GroupId, $SubjectId, $Delegatable).
  }.

defcall postGroupAdmissionPolicy(?GroupId, ?PolicyId, ?TrustEndorser) :-
  {
    postGroupAdmissionPolicy($ServerJVM, $ReqEnvs, $GroupId, $PolicyId, ?TrustEndorser).
  }.

defcall postGroupDelegation(?GroupId, ?SubGroupId, ?Delegatable) :-
  {
    postGroupDelegation($ServerJVM, $ReqEnvs, $GroupId, $SubGroupId, $Delegatable).
  }.

defcall updateGroupSet(?Token, ?Group) :-
  {
    updateGroupSet($ServerJVM, $ReqEnvs, $Token, $Group).
  }.

nestGroup(?GroupId, ?SubGroupId, ?Delegatable) :-
  ?GA := rootPrincipal(?GroupId),
  switchSelfTo(?GA),
  ?Token := postGroupDelegation(?GroupId, ?SubGroupId, ?Delegatable),
  ?SubjectId := rootPrincipal(?SubGroupId),
  switchSelfTo(?SubjectId),
  updateGroupSet(?Token, ?SubGroupId).

defcall postMembershipDelegation(?SubjectId, ?GroupId, ?Delegatable) :-
  {
    postMembershipDelegation($ServerJVM, $Envs, $SubjectId, $GroupId, $Delegatable).
  }.

delegateMembership(?GroupId, ?SubjectId, ?Delegatable) :-
  ?GA := rootPrincipal(?GroupId),
  switchSelfTo(?GA),
  ?Token := postMembershipDelegation(?SubjectId, ?GroupId, ?Delegatable),
  switchSelfTo(?SubjectId),
  updateSubjectSet(?Token).

defcall updateNameObjectSet(?Token, ?Scid) :-
  {
    updateNameObjectSet($ServerJVM, $ReqEnvs, $Token, $Scid).
  }.

defcall postNameDelegation(?Name, ?ParentScid, ?ChildScid) :-
  {
    postNameDelegation($ServerJVM, $ReqEnvs, $Name, $ParentScid, $ChildScid).
  }.

delegateName(?Name, ?ParentScid, ?ChildScid) :-
  ?DirPrincipalId := rootPrincipal(?ParentScid),
  switchSelfTo(?DirPrincipalId),
  ?Token := postNameDelegation(?Name, ?ParentScid, ?ChildScid),
  ?SubdirPrincipalId := rootPrincipal(?ChildScid),
  switchSelfTo(?SubdirPrincipalId),
  updateNameObjectSet(?Token, ?ChildScid).

defcall postDirectoryAccess(?GroupId, ?Scid) :-
  {
    postDirectoryAccess($ServerJVM, $ReqEnvs, $GroupId, $Scid).
  }.

defcall whoami() :-
  {
    whoami($ServerJVM, $ReqEnvs).
  }.

defcall queryMembership(?GroupId, ?SubjectId) :-
  {
    queryMembership($ServerJVM, $ReqEnvs, $GroupId, $SubjectId).
  }.

defcall queryName(?RootDir, ?Name) :-
  {
    queryName($ServerJVM, $ReqEnvs, $RootDir, $Name).
  }.

defcall accessNamedObject(?SubjectId, ?Name, ?RootDir) :-
  {
    accessNamedObject($ServerJVM, $ReqEnvs, $SubjectId, $Name, $RootDir).
  }.
