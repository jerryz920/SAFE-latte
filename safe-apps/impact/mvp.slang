import("../safe.slang").

//
// NS

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


// For required MVP root receipt.

defcon linkReceiptForDataset(?User, ?Project, ?DataScid, ?FlowScid) :-
    ?ReceiptToken := label("receipt: (?User, ?Project) completes ?FlowScid"),
{
//debug
    linked($User,$Project).
//debug
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


// Here are the NS entry points for MVP demo.
// Required arguments: ?user, ?project, ?dataScid, ?flowScid

defpost postCommonCompletionReceipt(?Project, ?FlowScid) :-
    [generateCommonCompletionReceipt(?Project, ?FlowScid)].

defpost postUserCompletionReceipt(?User, ?Project, ?FlowScid) :-
    [generateUserCompletionReceipt(?User, ?Project, ?FlowScid)].

defpost postLinkReceiptForDataset(?User, ?Project, ?DataScid, ?FlowScid) :-
    [linkReceiptForDataset(?User, ?Project, ?DataScid, ?FlowScid)].

//
// workflow publisher
//

defcon perFlowRule(?WFScid) :-
   spec('example generated workflow rule'),
{
//debug
gotrule($WFScid).
//debug
    complete($WFScid, ?U, ?NS, ?Project) :-
       ?NS:common(?Project, $WFScid),
       ?NS:complete(?U, ?Project, $WFScid).
//       eligibleProject(?Project),
//       trustedNS(?NS).

    label($WFScid).
}.

defpost postPerFlowRule(?WFScid) :-
    [perFlowRule(?WFScid)].

defguard letsDoACheck(?WFScid, ?T) :-
   ?WFpublisher := rootPrincipal(?WFScid),
   ?Token := label(?WFpublisher, ?WFScid),
{
    link($T).
//    link($Token).
    $WFpublisher:gotrule($WFScid)?
}.

// Data provider

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
//      eligibleProject(?Project),
//      trustedNS(?NS).
    putAccessRule($DataScid).

    link($IAWFtoken).
    link($RAWFtoken).
    label($DataScid).
}.

defpost postTwoFlowDataOwnerPolicy(?DataScid, ?RAWFScid, ?IAWFScid) :-
    [twoFlowDataOwnerPolicy(?DataScid, ?RAWFScid, ?IAWFScid)].

// Data server -- Presidio
// For debugging added two workflow scids: remove these.
// and also from mvp-client

defguard access(?DataScid, ?U, ?NS, ?Project, ?WF1, ?WF2) :-
   ?DataOwner := rootPrincipal(?DataScid),
   ?DataToken := label(?DataOwner, ?DataScid),
   ?ReceiptRootToken := label(?NS, "receipt root: (?U, ?Project) for ?DataScid"),
   ?WF1publisher := rootPrincipal(?WF1),
   ?WF2publisher := rootPrincipal(?WF2),
{
   link($DataToken).
   link($ReceiptRootToken).

//Debug
$NS:complete($U,$Project,$WF1)?
$NS:linked($U,$Project)?
$DataOwner:putAccessRule($DataScid)?
$WF1publisher:complete($WF1,$U,$NS,$Project)?
$WF2publisher:complete($WF2,$U,$NS,$Project)?

   grantAccess(?Owner, ?DataScid, ?U, ?NS, ?Project) :-
 //  // keep this out until satisfied:  trustedNS(NS),
     ?Owner:access(?DataScid, ?U, ?NS, ?Project).

  grantAccess($DataOwner, $DataScid, $U, $NS, $Project)?
}.




