// import("./plist-lib.slang").

// Endorser needs to call postEndorsementLink("trustPolicy/xxx").

//defcon createPodPolicy(?PolicyID, ?PodProperty) :-
//{
//    policy($PolicyID, "podProperty", $PodProperty).
//    label("endorsements/trustPolicy/$PolicyID").
//}.

defcon createPodPolicy(?PolicyID, ?PodProperty) :-
{
    endorsedConfigSet($PodProperty, $PolicyID).
    label("endorsements/trustPolicy/$PolicyID").
}.

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
// if the ImageMatcher matchaes its image, and rest of the list match the container config.
// 
// I didn't use list representation to construct "policy" statement is for easier implementation
// of "matching" some policy. It could be optimized such that images of each container in a Pod
// appears always in sort order, which can accelerate the policy matching process.

defpost postPodPolicy(?PolicyID, ?PodProperty) :-
    [createPodPolicy(?PolicyID, ?PodProperty)].

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

    // Checking spark job policy
    approveDriverGroup(?DriverGroup, ?PolicyID) :-
      ?GRoot := rootPrincipal(?DriverGroup),
      ?GRoot: memberByAttestedProperty(?DriverGroup, ?Prop),
      ?GRoot: trustedEndorserOn(?Prop, ?Endorser),
      ?Endorser: endorsedConfigSet(?Prop, ?ConfigSetID),
      checkConfigSet(?Endorser, ?ConfigSetID, ?PolicyID).

    checkConfigSet(P, PConfSet, CheckerConfigSet) :-
      P: policy(PConfSet, "image", Images),
      hasPolicy(CheckerConfigSet, "image", CheckerImages),
      subseq(Images, CheckerImages),
      checkConfigSetByImages(P, PConfSet, CheckerConfigSet, Images).

    checkConfigSetByImages(P, PConfigSet, CheckerConfigSet, [Img|Rest]) :-
      approvePropertyList(P, PConfigSet, Img, "required", CheckerConfigSet),
      approvePropertyList(P, PConfigSet, Img, "qualifier", ChekcerConfigSet),
      approvePropertyList(P, PconfigSet, Img, "prohibited", CheckerConfigSet),
      checkConfigSetByImages(P, PConfigSet, CheckerConfigSet, Rest).

    checkConfigSetByImages(P, PConfigSet, CheckerConfigSet, []).

    approvePropertyList(P, PConfigSet, Img, Category, CheckerConfigSet) :-
      "qualifier" = Category,
      P: policy(PConfigSet, Category, [Img|PList]),
      hasPolicy(CheckerConfigSet, "required", [[Img, Category]|CRequiredKeys]),
      propsPresent(CRequiredKeys, PList),
      hasPolicy(CheckerConfigSet, "qualifier", [[Img, Category]|CQualifiers]),
      esubseq(CQualifiers, PList),
      hasPolicy(CheckerConfigSet, "prohibited", [[Img, Category]|CProhibitedKeys]),
      \+( anyPropPresent(CProhibitedKeys, PList) ).

    approvePropertyList(P, PConfigSet, Img, Category, CheckerConfigSet) :-
      P: policy(PConfigSet, Category, [Img|PList]),
      hasPolicy(CheckerConfigSet, "required", [[Img, Category]|CRequiredKeys]),
      subseq(CRequiredKeys, PList),
      hasPolicy(CheckerConfigSet, "qualifier", [[Img, Category]|CQualifiers]),
      esubseq(CQualifiers, PList),
      hasPolicy(CheckerConfigSet, "prohibited", [[Img, Category]|CProhibitedKeys]),
      \+( intersecting(CProhibitedKeys, PList) ).

    approvePropertyList(P, PConfigSet, Img, Category, CheckerConfigSet) :-
      \+( P:policy(PConfigSet, Category, [Img|PList]) ).
}.

definit policyRules().