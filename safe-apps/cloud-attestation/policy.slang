

// Endorser needs to call postEndorsementLink("trustPolicy/xxx").

defcon createImagePolicy(?PolicyID, ?ImgWhiteList) :-
{
    policy($PolicyID, "image", $ImgWhiteList).
    label("endorsements/trustPolicy/$PolicyID").
}.

defcon createProhibitedKeysPolicy(?PolicyID, ?ConfProhibited) :-
{
    policy($PolicyID, "prohibited", $ConfProhibited).
    label("endorsements/trustPolicy/$PolicyID").
}.

defcon createRequiredKeysPolicy(?PolicyID,  ?ConfRequired) :-
{
    policy($PolicyID, "required", $ConfRequired).
    label("endorsements/trustPolicy/$PolicyID").
}.

defcon createQualifierKVsPolicy(?PolicyID, ?ConfQualifiers) :-
{
    policy($PolicyID, "qualifier", $ConfQualifiers).
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

defpost postImagePolicy(?PolicyID, ?ImgWhiteList) :-
    [createImagePolicy(?PolicyID, ?ImgWhiteList)].

defpost postProhibitedPolicy(?PolicyID, ?ConfProhibited) :-
    [createProhibitedKeysPolicy(?PolicyID, ?ConfProhibited)].

defpost postRequiredPolicy(?PolicyID,  ?ConfRequired) :-
    [createRequiredKeysPolicy(?PolicyID, ?ConfRequired)].

defpost postQualifierPolicy(?PolicyID, ?ConfQualifiers) :-
    [createQualifierKVsPolicy(?PolicyID, ?ConfQualifiers)].

defcon policyRules() :- 
{

    label("trustPolicyRules").

    // if endorsement occurs and trusted, then derive policy as well
    hasPolicy(ID, Type, Value) :-
	trustedEndorserOn("trustPolicy", E),
        E: policy(ID, Type, Value).

    // hasPolicy(ID, Type, Value) :-
    // 	trustedEndorserOn("trustPolicy", E),
    //     E: policy(ID, Type, Value),
    //     PRoot := rootPrincipal(ID),
    //     E = PRoot.

    hasPolicy(ID, Type, Value) :-
	policy(ID, Type, Value).
}.

definit policyRules().

