import("../safe.slang").

//
// Dataset owner (DSO).
//

defcon twoFlowDataOwnerPolicy(?DataScid, ?RAWFscid, ?IAWFscid) :-
   spec('example data owner authz rule with two approval workflows (e.g., research and infrastructure)'),
   ?RAWFpublisher := rootPrincipal(?RAWFscid),
   ?RAWFtoken := label(?RAWFpublisher, ?RAWFscid),
   ?IAWFpublisher := rootPrincipal(?IAWFscid),
   ?IAWFtoken := label(?IAWFpublisher, ?IAWFscid),
{
   access($DataScid, ?U, ?NS, ?Project) :- 
      $RAWFpublisher:complete($RAWFscid, ?U, ?NS, ?Project),
      $IAWFpublisher:complete($IAWFscid, ?U, ?NS, ?Project).
//    eligibleProject(?Project),
//    trustedNS(?NS).

    link($IAWFtoken).
    link($RAWFtoken).
    label($DataScid).
}.

defpost postTwoFlowDataOwnerPolicy(?DataScid, ?RAWFscid, ?IAWFscid) :-
    [twoFlowDataOwnerPolicy(?DataScid, ?RAWFscid, ?IAWFscid)].
