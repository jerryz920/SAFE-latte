//
// Researchers (including PIs)
//

defcon submitResearchProposal(?Project) :-
    spec("A researcher submits a research proposal."),
{
    subject($Subject, $BearerRef).
    researchProposal($Project).
    label("research-proposal/$Subject/$Project").
}.

defpost postProposalSubmission(?Project) :-
    [submitResearchProposal(?Project)]. 

defcon makeConfidentialityPledge(?Project) :-
    spec("A researcher makes a confidentiality pledge."),
{
    subject($Subject, $BearerRef).
    confidentialityPledge($Project).
    label("confidentiality-pledge/$Subject/$Project").
}.

defpost postConfidentialityPledge(?Project) :-
    [makeConfidentialityPledge(?Project)]. 

defcon makeIRBPledge(?Project) :-
    spec("A researcher makes an IRB pledge."),
{
    subject($Subject, $BearerRef).
    irbPledge($Project).
    label("irb-pledge/$Subject/$Project").
}.

defpost postIRBPledge(?Project) :-
    [makeIRBPledge(?Project)].

defcon makeReportingPledge(?Project) :-
    spec("A researcher makes a reporting pledge."),
{
    subject($Subject, $BearerRef).
    reportingPledge($Project).
    label("reporting-pledge/$Subject/$Project").
}.

defpost postReportingPledge(?Project) :-
    [makeReportingPledge(?Project)]. 

defcon makeBreachReportingPledge(?Project) :-
    spec("A researcher makes a breach reporting pledge."),
{
    subject($Subject, $BearerRef).
    breachReportingPledge($Project).
    label("breach-reporting-pledge/$Subject/$Project").
}.

defpost postBreachReportingPledge(?Project) :-
    [makeBreachReportingPledge(?Project)]. 

defcon makePersonnelPledge(?Project) :-
    spec("A researcher makes a personnel pledge."),
{
    subject($Subject, $BearerRef).
    personnelPledge($Project).
    label("personnel-Pledge/$Subject/$Project").
}.

defpost postPersonnelPledge(?Project) :-
    [makePersonnelPledge(?Project)]. 

defcon makeApprovedPurposePledge(?Project) :-
    spec("A researcher makes an approved purpose pledge."),
{
    subject($Subject, $BearerRef).
    approvedPurposePledge($Project).
    label("approved-purpose-pledge/$Subject/$Project").
}.

defpost postApprovedPurposePledge(?Project) :-
    [makeApprovedPurposePledge(?Project)]. 

defcon makeNoDisseminationPledge(?Project) :-
  spec("A researcher makes a no-dissemination pledge."),
  {
    subject($Subject, $BearerRef).
    noDisseminationPledge($Project).
    label("no-dissemination-pledge/$Subject/$Project").
  }.

defpost postNoDisseminationPledge(?Project) :-
    [makeNoDisseminationPledge(?Project)].