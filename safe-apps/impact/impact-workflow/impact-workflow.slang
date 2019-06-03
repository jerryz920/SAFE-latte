//
// Institution: niehs
//

defcon approveIRB(?Project) :-
    spec("An institution approves an IRB."),
{
    subject($Subject, $BearerRef).
    approvedIRB($Project).
    label("IRB-approval/$Subject/$Project").
}.

defpost postIRBApproval(?Project) :-
    [approveIRB(?Project)]. 

defcon workflowPolicySet(?WorkflowID, ?TermID) :- 
    spec("Policy set for workflow"),
{
    subject($Subject, $BearerRef).
    complete(?User, $WorkflowID, ?Age) :-
        ?User: accept($WorkflowID, $TermID),
        ?User: register($WorkflowID, $TermID, ?Age).
    label("workflow-policy/$WorkflowID/$TermID"). 
}.

//
// Infrastructure provider
//

defcon attestCompliantIP(?IPList) :-
    spec("An infrastructure provider attests the compliance of a list of IP addresses."),
{
    compliantIP($IPList).
    label("Compliant-IP").
}.

defpost postCompliantIP(?IPList) :-
    [attestCompliantIP(?IPList)].