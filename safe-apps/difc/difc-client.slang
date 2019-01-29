import("../strong/strong-client.slang").

defcall accessNamedObjectUnderDIFC(?SubjectId, ?Name, ?RootDir) :-
  {
    accessNamedObject($ServerJVM, $ReqEnvs, $SubjectId, $Name, $RootDir).
  }.

