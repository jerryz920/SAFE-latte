

// Endorser needs to call postEndorsementLink("trustPolicy/xxx").

defcon createImagePolicy(?PolicyID, ?ImgWhiteList) :-
{
   policy($PolicyID, "image", $ImgWhiteList).
   label("endorsements/trustPolicy/$PolicyID").
}.

defcon createProhibitedKeyPolicy(?PolicyID, ?ConfProhibited) :-
{
   policy($PolicyID, "prohibited", $ConfProhibited).
   label("endorsements/trustPolicy/$PolicyID").
}.

defcon createRequiredKeyPolicy(?PolicyID,  ?ConfRequired) :-
{
   policy($PolicyID, "required", $ConfRequired).
   label("endorsements/trustPolicy/$PolicyID").
}.

defcon createQualifierKeyPolicy(?PolicyID, ?ConfQualifiers) :-
{
   policy($PolicyID, "qualifier", ConfQualifiers).
   label("endorsements/trustPolicy/$PolicyID").
}.

// Logically each policy is composed by four lists.
// ImgWhiteList    [ImageMatcher, ImageMatcher, ImageMatcher, ...]
// ConfProhibited  [[ImageMatcher, k, k, k, k, k...], ...]
// ConfQualifiers  [[ImageMatcher, [k,v], [k,v], [k,v]...], ...]
// ConfRequired    [[ImageMatcher, k, k, k, k, k...], ...]
// 
// The semantic of the three list is: each element is a list that starts with an "ImageMatcher",
// which will match an image based on authorizer's trust setting. A container satisfies an element
// if the ImageMatcher matches its image, and rest of the list match the container config.
// 
// I didn't use list representation to construct "policy" statement is for easier implementation
// of "matching" some policy. It could be optimized such that images of each container in a Pod
// appears always in sort order, which can accelerate the policy matching process.

defpost postPolicy(?PolicyID, ?ImgWhiteList, ?ConfProhibited, ?ConfQualifiers, ?ConfRequired) :-
  [createPolicy(?PolicyID, ?ImgWhiteList, ?ConfProhibited, ?ConfQualifiers, ?ConfRequired)].


defcon policyRules() :- 
  {

	label("trustPolicyRules").

	// if endorsement occurs and trusted, then derive policy as well
	policy(ID, Type, Value) :-
	   E: policy(ID, Type, Value),
	   trustedEndorserOn("trustPolicy", E).

  }.

definit policyRules().

