import("../strong/strong.slang")

defcon difcAccessPolicyTargetingFile(?P, ?FileScid, ?Name, ?RootScid) :-
  spec('Local DIFC access policies targeting a file'),
  {
    groupAccessToName($P, ?Group, $Name, $RootScid) :- 
      ?FileOwner := rootPrincipal($FileScid), 
      ?FileOwner: accessToDir(?Group, $FileScid).

    groupAccessToName($P, ?Group, $Name, $RootScid)?

    label('DIFCAccessPolicyTargetingFile/$FileScid').
  }.


defcon difcAccessPolicyTargetingSet(?P, ?Name, ?RootDir) :-
  spec('Local DIFC access policies targeting a set'),
  {

    groupAccessToName($P, ?Group, $Name, $RootScid) :- 
      ?FileOwner: accessToDir(?Group, $FileScid).

    groupAccessToName($P, ?Group, $Name, $RootScid)?

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
