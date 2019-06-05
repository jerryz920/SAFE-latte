//
// Authorizer
//

defenv TrustedInP() :- '1bKw1ggQFkINurtu_MNmcr5n5RG8BcdqqyTPx2D0u5w'.

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

defpost postApprovalPolicy() :-
    [researchApprovalPolicySet()]. 

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

defpost postIPCompliancePolicy() :-
    [ipCompliancePolicySet()]. 

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

// TODO: Authorization of data access
