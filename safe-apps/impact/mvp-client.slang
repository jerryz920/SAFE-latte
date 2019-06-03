import("../safe-client.slang").

defenv ServerJVM() :- "localhost:7777".
defenv ReqEnvs() :- ":::".
defenv Self() :- "strong-1".

// As workflow publisher

defcall postPerFlowRule(?WFScid) :-
{
    postPerFlowRule($ServerJVM, $ReqEnvs, $WFScid).
}.

defcall letsDoACheck(?WFScid, ?T) :-
{
    letsDoACheck($ServerJVM, $ReqEnvs, $WFScid, $T).
}.


// As notary service.

defcall postCommonCompletionReceipt(?Project, ?FlowScid) :-
{
    postCommonCompletionReceipt($ServerJVM, $ReqEnvs, $Project, $FlowScid).
}.

defcall postUserCompletionReceipt(?User, ?Project, ?FlowScid) :-
{
    postUserCompletionReceipt($ServerJVM, $ReqEnvs, $User, $Project, $FlowScid).
}.

defcall postLinkReceiptForDataset(?User, ?Project, ?DataScid, ?FlowScid) :-
{
    postLinkReceiptForDataset($ServerJVM, $ReqEnvs, $User, $Project, $DataScid, $FlowScid).
}.

defcall checkComplete(?U, ?NS, ?Project, ?WF, ?T) :-   
{
    checkComplete($ServerJVM, $ReqEnvs, $U, $NS, $Project, $WF, $T).
}.


// As data owner

defcall postTwoFlowDataOwnerPolicy(?DataScid, ?RAWFscid, ?IAWFscid) :-
{
    postTwoFlowDataOwnerPolicy($ServerJVM, $ReqEnvs, $DataScid, $RAWFscid, $IAWFscid).
}.

// As data server
// For debugging added two workflow scids: remove these.


defcall access(?DataScid, ?U, ?NS, ?Project) :-
{
    access($ServerJVM, $ReqEnvs, $DataScid, $U, $NS, $Project).
}.



