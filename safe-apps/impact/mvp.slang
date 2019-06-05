import("../safe.slang").

//
// Notary Service (NS): internal certificate constructors.

defcon generateCommonCompletionReceipt(?Project, ?FlowScid) :-
{
   common($Project, $FlowScid).
   label("receipt: common completion for ($Project) on $FlowScid"). 
}.

defcon generateUserCompletionReceipt(?User, ?Project, ?FlowScid) :-
   ?ReceiptToken := label("receipt: common completion for (?Project) on ?FlowScid"),
{
   complete($User, $Project, $FlowScid).
   link($ReceiptToken).
   label("receipt: ($User, $Project) completes $FlowScid"). 
}.

//
// NS: for required MVP root receipt.  The NS calls this once for each workflow required to access
// the dataset.  One possibly confusing aspect: the receipt links for each call all end up in the same
// certificate.
//
defcon linkReceiptForDataset(?User, ?Project, ?DataScid, ?FlowScid) :-
    ?ReceiptToken := label("receipt: (?User, ?Project) completes ?FlowScid"),
{
    link($ReceiptToken).
    label("receipt root: ($User, $Project) for $DataScid"). 
}.

// Debug
defguard checkComplete(?U, ?NS, ?Project, ?WF, ?T) :-
{
  link($T).
  $NS:common($Project,$WF)?
  $NS:complete($U,$Project,$WF)?
}.

//
// NS REST entry points
// Required arguments: ?user, ?project, ?dataScid, ?flowScid
//

defpost postCommonCompletionReceipt(?Project, ?FlowScid) :-
    [generateCommonCompletionReceipt(?Project, ?FlowScid)].

defpost postUserCompletionReceipt(?User, ?Project, ?FlowScid) :-
    [generateUserCompletionReceipt(?User, ?Project, ?FlowScid)].

defpost postLinkReceiptForDataset(?User, ?Project, ?DataScid, ?FlowScid) :-
    [linkReceiptForDataset(?User, ?Project, ?DataScid, ?FlowScid)].

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
// Data provider (DP).
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

//
// Data server (DS)-- Presidio.
//

defguard access(?DataScid, ?U, ?NS, ?Project) :-
   ?DataOwner := rootPrincipal(?DataScid),
   ?DataToken := label(?DataOwner, ?DataScid),
   ?ReceiptRootToken := label(?NS, "receipt root: (?U, ?Project) for ?DataScid"),
{
   link($DataToken).
   link($ReceiptRootToken).

   grantAccess(?Owner, ?DataScid, ?U, ?NS, ?Project) :-
 //  trustedNS(NS),
     ?Owner:access(?DataScid, ?U, ?NS, ?Project).

   grantAccess($DataOwner, $DataScid, $U, $NS, $Project)?
}.




