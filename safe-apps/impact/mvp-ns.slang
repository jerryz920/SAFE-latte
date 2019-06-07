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
