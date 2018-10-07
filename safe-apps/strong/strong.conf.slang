//defenv RootDir() :- "ZF67xzvOPvC2IKWfvHWCLqcq7bkZRscL5FFKlQeyHiQ=:root".

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
