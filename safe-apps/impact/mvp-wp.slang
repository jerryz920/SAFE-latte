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
