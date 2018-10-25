import("../safe.slang").
import("strong.conf.slang").

//
// Group Authority 
//

defcon addGroupMember(?Group, ?User, ?Delegatable) :-
  spec('Add a user into a group'),
  ?GroupRef := label($Self, "groups/?Group"),
  {
    groupMember($Group, $User, $Delegatable).
    link($GroupRef).
    label("groupMember/$Group/$User").     (* this link should be saved in the subject set of ?User *)
  }.

defpost postGroupMember(?Group, ?User, ?Delegatable) :- [addGroupMember(?Group, ?User, ?Delegatable)].

defcon delegateGroup(?Group, ?SubGroup, ?Delegatable) :-
  spec('Delegate administration to another group'), (* Membership is granted if membership of sub-group is granted *)
  ?GroupRef := label($Self, "groups/?Group"),
  {
    nestGroup($Group, $SubGroup, $Delegatable).
    link($GroupRef).
    label("delegateGroup/$Group/$SubGroup").  (* this link should be saved in the ID set of ?SubGroup *)
  }.

defpost postGroupDelegation(?Group, ?SubGroup, ?Delegatable) :- [delegateGroup(?Group, ?SubGroup, ?Delegatable)].

defcon addTokenToGroupSet(?Token, ?Group) :-
  spec("Add a link to a group's ID set. Invoked on delegation to this group"),
  {
    link($Token).
    label("groups/$Group").
  }.

defpost updateGroupSet(?Token, ?Group) :- [addTokenToGroupSet(?Token, ?Group)].


//
// Group member
//

defcon delegateGroupMembership(?User, ?Group, ?Delegatable) :-
  spec('Delegate group membership to another user'),
  ?SubjectSetRef := label("subject($Self)"),
  {
    delegateMembership($User, $Group, $Delegatable).
    link($SubjectSetRef).
    label("membershipDelegation/$Group/$User").     (* this link should be saved in the subject set of ?User *)
  }.

defpost postMembershipDelegation(?User, ?Group, ?Delegatable) :- [delegateGroupMembership(?User, ?Group, ?Delegatable)].


//
// Naming authority
//

defcon addTokenToNameObjectSet(?Token, ?Scid) :-
  spec("Add a link to an object set"),
  {
    link($Token).
    label("$Scid").
  }.

defpost updateNameObjectSet(?Token, ?Scid) :- [addTokenToNameObjectSet(?Token, ?Scid)].

defcon createNameEntry(?NameComponent, ?ChildScid, ?ParentScid) :-
  spec('Create a name entry'),
  ?ParentToken := label(?ParentScid),
  {
    link($ParentToken).
    nameObject($NameComponent, $ChildScid, $ParentScid).
    nameObject2($ParentScid, $NameComponent, $ChildScid).
    label("$ParentScid/$NameComponent").
  }.

defpost postNameDelegation(?NameComponent, ?ChildScid, ?ParentScid) :- 
  [createNameEntry(?NameComponent, ?ChildScid, ?ParentScid)].


defcon grantAccess(?Group, ?DirScid) :-
  spec('Grant group access to directory'),
  {
    accessToDir($Group, $DirScid).
    label("$DirScid").
  }.

defpost postDirectoryAccess(?Group, ?DirScid) :- [grantAccess(?Group, ?DirScid)].


//
// Guard
//

defcon memberSet() :-
  spec('Local policies on group membership'),
  {
    membership(?Group, ?User) :-
      membership(?Group, ?User, _).
  
   //
   // If the group root can automatically have membership of the group, 
   // enable this rule.
   //
   // membership(?Group, ?User, true) :-
   //   ?GRoot := rootPrincipal(?Group),
   //   ?GRoot = ?User.
   //

    membership(?Group, ?User, ?Delegatable) :-
      ?GRoot := rootPrincipal(?Group), 
      ?GRoot: groupMember(?Group, ?User, ?Delegatable).
    
    membership(?Group, ?User, ?Delegatable) :-
      ?Delegator: delegateMembership(?User, ?Group, ?Delegatable),
      membership(?Group, ?Delegator, true).

    membership(?Group, ?User, ?Delegatable) :-
      ?GRoot := rootPrincipal(?Group),
      ?GRoot: nestGroup(?Group, ?SubGroup, true), 
      membership(?SubGroup, ?User, ?Delegatable).

    membership(?Group, ?User, ?Delegatable) :-
      ?GRoot := rootPrincipal(?Group),
      ?GRoot: nestGroup(?Group, ?SubGroup, false), 
      ?SubGroupRoot := rootPrincipal(?SubGroup),
      ?SubGroupRoot: groupMember(?SubGroup, ?User, ?Delegatable).

    label('standard-membership-policy').
  }.

definit memberSet().


defcon checkDirectNameObject(?Dir, ?NameComponent) :-
  spec("Check if a name object is directly under a dir"),
  {
    directNameObject(?Scid) :- 
      ?NameAuthority := rootPrincipal($Dir),
      ?NameAuthority: nameObject($NameComponent, ?Scid, $Dir).

    directNameObject(?Scid)?
    label("$Dir-$NameComponent").
  }.

resolve(?Dir, ?Name, ?Scid, ?LastCertToken) :-
  singleComponent(?Name),
  ?RulesRef := checkDirectNameObject(?Dir, ?Name),
  ?DirAuthority := rootPrincipal(?Dir),
  ?ObjDelToken := label(?DirAuthority, "?Dir/?Name"),
  ?ScidSet := inferSet(?RulesRef, ?ObjDelToken),
  ?ObjScid := getNthArgFromSlogset(?ScidSet, 0),
  unify(?Scid, ?ObjScid),
  unify(?LastCertToken, ?ObjDelToken).

resolve(?Dir, ?Name, ?Scid, ?LastCertToken) :-
  splitHead(?Name, ?FirstComponent, ?Tail),
  ?RulesRef := checkDirectNameObject(?Dir, ?FirstComponent),
  ?DirAuthority := rootPrincipal(?Dir),
  ?ObjDelToken := label(?DirAuthority, "?Dir/?FirstComponent"),
  ?SubDirSet := inferSet(?RulesRef, ?ObjDelToken),
  ?SubDir := getNthArgFromSlogset(?SubDirSet, 0),
  resolve(?SubDir, ?Tail, ?Scid, ?LastCertToken).

defcon srnEvaluation() :-
  spec("Rules for SRN certified evaluation, in a bottom-up fashion"),
  {
    srnNameToID(?RootDir, ?Name, ?Scid) :-
      singleComponent(?Name),
      ?RootAuthority := rootPrincipal(?RootDir),
      ?RootAuthority: nameObject(?Name, ?Scid, ?RootDir).

    srnNameToID(?RootDir, ?Name, ?Scid) :-
      splitLast(?Name, ?Init, ?LastComponent),
      srnNameToID(?RootDir, ?Init, ?Dir),
      ?DirAuthority := rootPrincipal(?Dir),
      ?DirAuthority: nameObject(?LastComponent, ?Scid, ?Dir).

    srnIDPathTo(?UpstreamScid, ?DownstreamScid) :-
      ?UpstreamScid = ?DownstreamScid.

    srnIDPathTo(?UpstreamScid, ?DownstreamScid) :-
      ?UpstreamRoot := rootPrincipal(?UpstreamScid),
      ?UpstreamRoot: nameObject2(?UpstreamScid, ?Name, ?MiddleScid),
      srnIDPathTo(?MiddleScid, ?DownstreamScid).

    label("SRN-standard-evaluation").
  }.

definit srnEvaluation().

defcon accessPolicySet() :-
  spec("Policy for access control over named objects"),
  {
    allowAccess(?Group, ?Dir) :-
      ?Principal: accessToDir(?Group, ?Dir),
      ?DRoot := rootPrincipal(?Dir),
      ?Principal = ?DRoot.

    approveAccess(?P, ?Name, ?RootDir) :-  
      srnNameToID(?RootDir, ?Name, ?Scid),
      allowAccess(?Group, ?Dir),
      srnIDPathTo(?Dir, ?Scid),
      membership(?Group, ?P).

    label("standard-access-policy").
  }.

definit accessPolicySet().

defguard whoami() :-
  spec("Query principal id"),
  {
    principalId($Self).
    principalId(?X)?
  }.

defguard queryMembership(?Group, ?SubjectId) :-
  spec("Query the group membership of a principal"),
  ?MembershipPolicy := label('standard-membership-policy'),
  {
    link($MembershipPolicy).
    link($BearerRef).
    membership($Group, $SubjectId)?
  }.

//
// A generic guard for querying names under a naming hierarchy
//

defguard queryName(?RootDir, ?Name) :-
  spec("Query a name"),
  resolve(?RootDir, ?Name, ?Scid, ?LastCertToken),
  ?SRNEvalRulesRef := label("SRN-standard-evaluation"),
  ?ObjRoot := rootPrincipal(?Scid),
  ?ObjToken := label(?ObjRoot, ?Scid),
  {
    link($ObjToken).
    link($SRNEvalRulesRef).
    srnNameToID($RootDir, $Name, ?Scid)?
  }.

defguard accessNamedObject(?P, ?Name, ?RootDir) :-
  spec("Check if a principal can access a named object"),
  resolve(?RootDir, ?Name, ?Scid, ?LastCertToken),
  ?ObjRoot := rootPrincipal(?Scid),
  ?ObjToken := label(?ObjRoot, ?Scid),
  ?SRNEvalRulesRef := label("SRN-standard-evaluation"),
  ?MembershipPolicyRef := label("standard-membership-policy"),
  ?AccessPolicyRef := label("standard-access-policy"),
  {
    link($ObjToken).
    link($SRNEvalRulesRef).
    link($MembershipPolicyRef).
    link($AccessPolicyRef).
    link($BearerRef).
    approveAccess($P, $Name, $RootDir)?
  }.
