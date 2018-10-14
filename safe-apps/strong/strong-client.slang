import("../safe-client.slang").

defenv ServerJVM() :- "152.3.136.26:6666".
defenv Envs() :- ":::".
defenv Self() :- "strong-1".

defcall postGroupMember(?GroupId, ?SubjectId, ?Delegatable) :-
  {
    postGroupMember($ServerJVM, $Envs, $GroupId, $SubjectId, $Delegatable).
  }.

defcall postGroupDelegation(?GroupId, ?SubGroupId, ?Delegatable) :-
  {
    postGroupDelegation($ServerJVM, $Envs, $GroupId, $SubGroupId, $Delegatable).
  }.

defcall updateGroupSet(?Token, ?Group) :-
  {
    updateGroupSet($ServerJVM, $Envs, $Token, $Group).
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
    updateNameObjectSet($ServerJVM, $Envs, $Token, $Scid).
  }.

defcall postNameDelegation(?NameComponent, ?ChildScid, ?ParentScid) :-
  {
    postNameDelegation($ServerJVM, $Envs, $NameComponent, $ChildScid, $ParentScid).
  }.

delegateName(?NameComponent, ?DirPrincipalId, ?DirUUID, ?SubdirPrincipalId, ?SubdirUUID) :-
  switchSelfTo(?DirPrincipalId),
  ?Token := postNameDelegation(?NameComponent, "?SubdirPrincipalId:?SubdirUUID", "?DirPrincipalId:?DirUUID"),
  switchSelfTo(?SubdirPrincipalId),
  updateObjectSet(?Token, "?SubdirPrincipalId:?SubdirUUID").  

defcall postDirectoryAccess(?GroupId, ?Scid) :-
  {
    postDirectoryAccess($ServerJVM, $Envs, $GroupId, $Scid).
  }.

defcall whoami() :-
  {
    whoami($ServerJVM, $Envs).
  }.

defcall queryMembership(?GroupId, ?SubjectId) :-
  {
    queryMembership($ServerJVM, $Envs, $GroupId, $SubjectId).
  }.

defcall queryName(?RootDir, ?Name) :-
  {
    queryName($ServerJVM, $Envs, $RootDir, $Name).
  }.

defcall accessNamedObject(?SubjectId, ?Name, ?RootDir) :-
  {
    accessNamedObject($ServerJVM, $Envs, $SubjectId, $Name, $RootDir).
  }.
