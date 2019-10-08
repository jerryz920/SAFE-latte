

// Endorser needs to call postEndorsementLink("trustPolicy/xxx").

defcon createPolicy(?PolicyID, ?ImgWhiteList, ?ConfProhibited, ?ConfQualifiers, ?ConfRequired) :-
{
   policy($PolicyID, $ImgWhiteList, $ConfProhibited, $ConfQualifiers, $ConfRequired).
   label("endorsements/trustPolicy/$PolicyID").
}.

defpost postPolicy(?PolicyID, ?ImgWhiteList, ?ConfProhibited, ?ConfQualifiers, ?ConfRequired) :-
  [createPolicy(?PolicyID, ?ImgWhiteList, ?ConfProhibited, ?ConfQualifiers, ?ConfRequired)].


defcon policyRules() :- 
  {

	label("trustPolicyRules").

	// if endorsement occurs and trusted, then derive policy as well
	policy(PID, I, P, Q, R) :-
	  E: policy(PID, I, P, Q, R),
	  trustedEndorserOn("trustPolicy", E).
  }.

definit policyRules().

