//
// Data Provider (DP)
//

defcon acknowledgeProposal(?Project) :-
    spec("A data provider acknowledges a research proposal."),
{
    subject($Subject, $BearerRef).
    acknowledgedProposal($Project).
    label("proposal-acknowledgment/$Subject/$Project").
}.

defpost postProposalAcknowlegement(?Project) :-
    [acknowledgeProposal(?Project)]. 

defcon approveProposal(?Project) :-
    spec("A data provider approves a research proposal."),
{
    subject($Subject, $BearerRef).
    approvedProposal($Project).
    label("proposal-approval/$Subject/$Project").
}.

defpost postProposalApproval(?Project) :-
    [approveProposal(?Project)].