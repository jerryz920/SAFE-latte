import("../strong/strong.slang")

defcon difcAccessPolicyTargetingFile(?P, ?FileScid, ?Name, ?RootScid) :-
  spec('Local DIFC access policies targeting a file'),
  {
    approveAccessByMembership($P, ?Tag, $Name, $RootScid) :- 
      ?FileOwner := rootPrincipal($FileScid), 
      ?FileOwner: accessToDir(?Tag, $FileScid).

    approveAccessByMembership($P, ?Tag, $Name, $RootScid)?

    label('DIFCAccessPolicyTargetingFile/$FileScid').
  }.


defcon difcAccessPolicyTargetingSet(?P, ?Name, ?RootScid) :-
  spec('Local DIFC access policies targeting a set'),
  {

    approveAccessByMembership($P, ?Tag, $Name, $RootScid) :- 
      ?FileOwner: accessToDir(?Tag, ?FileScid),
      ?Froot := rootPrincipal(?FileScid),
      ?FileOwner = ?Froot.

    approveAccessByMembership($P, ?Tag, $Name, $RootScid)?

    label('DIFCAccessPolicyTargetingSet/$RootDir/$Name').
  }.


defguard accessNamedObjectUnderDIFC(?P, ?Name, ?RootDir) :-
  spec("Check if a principal can access a named object"),
  resolve(?RootDir, ?Name, ?Scid, ?LastCertToken),
  ?ObjRoot := rootPrincipal(?Scid),
  ?ObjSet := label(?ObjRoot, ?Scid),
  ?DifcRulesRef := difcAccessPolicyTargetingSet(?P, ?Name, ?RootDir),
  ?SubgoalsRef := inferQuerySet(?DifcRulesRef, ?ObjSet),
  ?SRNEvalRulesRef := label("SRN-standard-evaluation"),
  ?MembershipPolicyRef := label("standard-membership-policy"),
  ?AccessPolicyRef := label("standard-access-policy"),
  {
    link($ObjSet).
    link($SRNEvalRulesRef).
    link($MembershipPolicyRef).
    link($AccessPolicyRef).
    link($BearerRef).
  }.
