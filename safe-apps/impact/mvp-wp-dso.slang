import("../safe.slang").
//
// Workflow Publisher (WP).
//

defcon perFlowRule(?WFScid) :-
   spec('example generated workflow rule'),
{
   complete($WFScid, ?U, ?NS, ?Project) :-
       ?NS:common(?Project, $WFScid),
       ?NS:complete(?U, ?Project, $WFScid).
//     eligibleProject(?Project),
//     trustedNS(?NS).

     label($WFScid).
}.

defpost postPerFlowRule(?WFScid) :-
    [perFlowRule(?WFScid)].

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
