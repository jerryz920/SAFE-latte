// This is a starting script for project ImPACT based on the research
// approval workflow at NIEHS.

//import("../strong/strong.slang").

defenv TrustedInP() :- '1bKw1ggQFkINurtu_MNmcr5n5RG8BcdqqyTPx2D0u5w'.

//
// Researchers (including PI)
//

defcon submitResearchProposal(?Project) :-
  spec("A researcher submits a research proposal."),
  {
    subject($Subject, $BearerRef).
    researchProposal($Project).
    label("research-proposal/$Subject/$Project").
  }.

defpost postProposalSubmission(?Project) :- [submitResearchProposal(?Project)]. 

defcon makeConfidentialityPledge(?Project) :-
  spec("A researcher makes a confidentiality pledge."),
  {
    subject($Subject, $BearerRef).
    confidentialityPledge($Project).
    label("confidentiality-pledge/$Subject/$Project").
  }.

defpost postConfidentialityPledge(?Project) :- [makeConfidentialityPledge(?Project)]. 

defcon makeIRBPledge(?Project) :-
  spec("A researcher makes an IRB pledge."),
  {
    subject($Subject, $BearerRef).
    irbPledge($Project).
    label("irb-pledge/$Subject/$Project").
  }.

defpost postIRBPledge(?Project) :- [makeIRBPledge(?Project)].

defcon makeReportingPledge(?Project) :-
  spec("A researcher makes a reporting pledge."),
  {
    subject($Subject, $BearerRef).
    reportingPledge($Project).
    label("reporting-pledge/$Subject/$Project").
  }.

defpost postReportingPledge(?Project) :- [makeReportingPledge(?Project)]. 

defcon makeBreachReportingPledge(?Project) :-
  spec("A researcher makes a breach reporting pledge."),
  {
    subject($Subject, $BearerRef).
    breachReportingPledge($Project).
    label("breach-reporting-pledge/$Subject/$Project").
  }.

defpost postBreachReportingPledge(?Project) :- [makeBreachReportingPledge(?Project)]. 

defcon makePersonnelPledge(?Project) :-
  spec("A researcher makes a personnel pledge."),
  {
    subject($Subject, $BearerRef).
    personnelPledge($Project).
    label("personnel-Pledge/$Subject/$Project").
  }.

defpost postPersonnelPledge(?Project) :- [makePersonnelPledge(?Project)]. 

defcon makeApprovedPurposePledge(?Project) :-
  spec("A researcher makes an approved purpose pledge."),
  {
    subject($Subject, $BearerRef).
    approvedPurposePledge($Project).
    label("approved-purpose-pledge/$Subject/$Project").
  }.

defpost postApprovedPurposePledge(?Project) :- [makeApprovedPurposePledge(?Project)]. 

defcon makeNoDisseminationPledge(?Project) :-
  spec("A researcher makes a no-dissemination pledge."),
  {
    subject($Subject, $BearerRef).
    noDisseminationPledge($Project).
    label("no-dissemination-pledge/$Subject/$Project").
  }.

defpost postNoDisseminationPledge(?Project) :- [makeNoDisseminationPledge(?Project)]. 


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

defpost postProposalAcknowlegement(?Project) :- [acknowledgeProposal(?Project)]. 

defcon approveProposal(?Project) :-
  spec("A data provider approves a research proposal."),
  {
    subject($Subject, $BearerRef).
    approvedProposal($Project).
    label("proposal-approval/$Subject/$Project").
  }.

defpost postProposalApproval(?Project) :- [approveProposal(?Project)]. 


defcon twoFlowDataOwnerPolicy(?DataScid, ?RAWFscid, ?IAWFscid) :-
    spec('example data owner authz rule with two approval workflows (e.g., research and infrastructure)'),
    ?RAWFpublisher := rootPrincipal(?RAWFscid),
    ?RAWFtoken := label(?RAWFpublisher, ?RAWFscid),
    ?IAWFpublisher := rootPrincipal(?IAWFscid),
    ?IAWFtoken := label(?IAWFpublisher, ?IAWFscid),
{
 access($DataScid, ?u, ?NS, ?project) :- 
   $RAWFpublisher:complete($RAWFscid, ?u, ?NS),
   $IAWFpublisher: complete($IAWFscid, ?u, ?NS),
   eligibleProject(?project),
   trustedNS(?NS).

 link($IAWFtoken).
 link($RAWFtoken).
 label($DataScid).
}

defpost postTwoFlowPolicy(?DataScid, ?RAWFscid, ?IAWFscid) :-
  [twoFlowDataOwnerPolicy(?DataScid, ?RAWFscid, ?IAWFscid)].



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

defpost postIRBApproval(?Project) :- [approveIRB(?Project)]. 

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

defpost postCompliantIP(?IPList) :- [attestCompliantIP(?IPList)]. 

//
// Notary service
//
defcon generateCompletionReceipt(?user, ?project, ?flowScid, ?userFormScid) :-
{
   complete($user, $project, $userFormScid).
   label("receipt: ($user, $project) completes $flowScid"). 
}.

defpost postCompletionReceipt(?user, ?project, ?flowScid, ?userFormScid) :-
  [generateCompletionReceipt(?user, ?project, ?flowScid, ?userFormScid)].

//
// Workflow publisher
//
defcon perFlowRule(?WFScid) :-
    spec('example generated workflow rule'),
{
  complete($WFScid, ?u, ?NS, ?project) :-
     ?NS:complete(?project, commonFormScid1),
     ?NS:complete(?u, ?project, userformScid1),
     eligibleProject(?project),
     trustedNS(?NS).    
}

defpost postFlowRule(?WFScid) :- [perFlowRule(?WFScid)].

 
//
// Authorizer
//

defcon researchApprovalPolicySet() :-
  spec("Standard policy for research approval."),
  {
    approveAccess(?Principal, ?DataSet, ?Project) :-
      member(?Principal, ?Project),
      projectPI(?PI, ?Project),
      ownData(?DP, ?DataSet),
      ?PI: researchProposal(?Project),
      ?DP: acknowledgedProposal(?Project),
      ?DP: approvedProposal(?Project),
      ?Principal: irbPledge(?Project),
      ?Principal: confidentialityPledge(?Project),
      ?Principal: reportingPledge(?Project),
      ?Principal: breachReportingPledge(?Project),
      ?Principal: personnelPledge(?Project),
      ?Principal: approvedPurposePledge(?Project),
      ?Principal: noDisseminationPledge(?Project).

    label("standard-research-approval-policy").
  }.

defpost postApprovalPolicy() :- [researchApprovalPolicySet()]. 

definit researchApprovalPolicySet().

defcon ipCompliancePolicySet() :-
  spec("Standard policy for IP compliance."),
  {
    approveAccessFromIP(?IP) :-
      trustedInfrastructureProvider(?InP),
      ?InP: compliantIP(?IP).

    approveAccessFromIP(?IP) :-
      trustedInfrastructureProvider(?InP),
      ?InP: compliantIP(?IPList),
      member(?IP, ?IPList).

    label("standard-ip-compliance-policy").
  }.

defpost postIPCompliancePolicy() :- [ipCompliancePolicySet()]. 

definit ipCompliancePolicySet().


// Guards

defcon anchorSet() :-
  ?CompliantIPSet := label($TrustedInP, "Compliant-IP"),
  {
    link($CompliantIPSet).
    trustedInfrastructureProvider($TrustedInP).
    label("impact/anchor-set").
  }.

definit anchorSet().


defguard checkOriginAddress(?IP) :-
  spec("Guard for authorizer at the storage"),
  ?AnchorRef := label("impact/anchor-set"),
  ?NetworkPolicyRef := label("standard-ip-compliance-policy"),
  {
    link($AnchorRef).
    link($NetworkPolicyRef).
    approveAccessFromIP($IP)?
  }.

// Authorization of data access
defguard access(?dataScid, ?u, ?NS, ?project, ?RAWFscid, ?IAWFscid) :-
    ?dataOwner := rootPrincipal(?dataScid),
    ?RAWFpublisher := rootPrincipal(?RAWFscid),
    ?RAWFtoken := label(?RAWFpublisher, ?RAWFscid),
    ?IAWFpublisher := rootPrincipal(?IAWFscid),
    ?IAWFtoken := label(?IAWFpublisher, ?IAWFscid),
    ?RAWFuserReceipt := label(?NS, "receipt: ($u, $project) completes $RAWFscid"),
    ?IAWFuserReceipt := label(?NS, "receipt: ($u, $project) completes $IAWFscid"),
{
   link($dataScid).
   link($IAWFuserReceipt).
   link($RAWFuserReceipt).

   grantAccess(?owner, ?dataScid, ?u, ?NS, ?project) :-
      trustedNS(NS),
      ?owner:access(?dataScid, ?u, ?NS, ?project).

   grantAccess(?dataOwner, ?DataScid, ?u, ?NS, ?project)?
}