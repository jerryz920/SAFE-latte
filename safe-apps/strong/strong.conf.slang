defenv RootDir() :- "ZF67xzvOPvC2IKWfvHWCLqcq7bkZRscL5FFKlQeyHiQ=:root".

defcon srnEvaluation() :-
  spec("Rules for SRN certified evaluation, in a bottom-up fashion"),
  {
    srnNameToID(?Name, ?Scid) :-
      singleComponent(?Name),
      ?RootAuthority := rootPrincipal($RootDir),
      ?RootAuthority: nameObject(?Name, ?Scid, $RootDir).

    srnNameToID(?Name, ?Scid) :-
      splitLast(?Name, ?Init, ?LastComponent),
      srnNameToID(?Init, ?Dir),
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
