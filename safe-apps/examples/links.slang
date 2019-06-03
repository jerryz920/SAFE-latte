
//
// Demonstrates linking and labeling.
// The idea here is that a collection of principals issue simple certificates with zero
// links (an anchor) or one link.  Each certificate has a name assigned by its issuer.
// You can construct
// a chain and then query if a particular named certificate is in the chain.  Each
// issuer has its own name space for certificates.
//
// Warning: with this code, if an issuer reissues a certificate with a given name, it overwrites the
// the previous version.  If new version embeds a different link, then the chain rooted
// in the old version is unlinked.  It is still reachable if you know the token.
//
// Run this in a SAFE engine and hit it with curls or slang-shell.
// It has primitives to build chains and query them in various ways.  
//

import("../safe.slang").

//
// Create a basic labeled (named) logic set.  Returns a token.
// This logic set/cert has zero links so we call it an "anchor".
//

defcon conAnchor(?Name) :-
{
   nameEntry($Name, 0).
   label($Name). 
}.

defpost dropAnchor(?Name) :-
   [conAnchor(?Name)].

//
// Create a labeled logic set that links (includes) another set by token.
// E.g.,  the issuer might pass the token to the caller out-of-band and the
// caller passes the token in to link to the target cert.
//

defcon conLink(?Name, ?PrevToken) :-
{
   nameEntry($Name, 0).
   link($PrevToken).
   label($Name). 
}.

defpost dropLink(?Name, ?Token) :-
   [conLink(?Name, ?Token)].


//
// Create a labeled logic set that links (includes) another set by name.
// This variant shows how to synthesize a link knowing the label.
// This variant presumes that the link target is a cert issued by $Self.
// (There should be a slang builtin for that.)
//

defcon conLinkByName(?Name, ?PrevName) :-
   ?PrevToken = label(?PrevName),
{
   nameEntry($Name, 0).
   link($PrevToken).
   label($Name). 
}.

defpost dropLinkByName(?Name, ?PrevName) :-
   [conLinkByName(?Name, ?PrevName)].

//
// Create a labeled logic set that links (includes) another set by name.
// This one shows how to synthesize a link knowing the issuer and the label.
// For this variant the issuer of the target could be $Self or anyone.
//

defcon conCrossLinkByName(?Name, ?PrevName, ?Owner) :-
   ?PrevToken = label(?Owner, ?PrevName),
{
   nameEntry($Name, 0).
   link($PrevToken).
   label($Name). 
}.

defpost dropCrossLinkByName(?Name, ?PrevName, ?Owner) :-
   [conCrossLinkByName(?Name, ?PrevName, ?Owner)].

//
// Check to see if a name is present in a linked set (chain) rooted in a token.
// (According to a specified issuer who issued the cert with that name.)
// This demonstrates a query against logic statements spoken by another party.
//
defguard queryPresent(?Name, ?Owner, ?RootToken) :-
{
   link($RootToken).
   $Owner:nameEntry($Name, ?Value)?
}.

//
// Check to see if a name is present in a linked set (chain) rooted in a token.
// This variant "believes" that name is present only if "I said it", i.e., $Self
// is the issuer of a certificate with that name in the chain.
//

defguard queryInHere(?Name, ?RootToken) :-
{
   link($RootToken).
   nameEntry($Name, ?Value)?
}.

//
// Check to see if a name is present in a linked set (chain) rooted in a named set.
// (According to a specific issuer who issued the cert with that name.)
//

defguard queryPresentByName(?Name, ?Owner, ?RootName, ?RootOwner) :-
   ?RootToken = label(?RootOwner, ?RootName),
{
   link($RootToken).
   $Owner:nameEntry($Name, ?Value)?
}.

//
// Cons and postcell are for a future extension to build general nested link lists (like lisp).
//

defcon cons(?CarToken, ?CdrToken) :-
{
   link($CarToken).
   link($CdrToken).
   label("car $CarToken cdr $CdrToken"). 
}.

defpost postCell(?CarToken, ?CdrToken) :-
   [cons(?CarToken, ?CdrToken)].


//
// The following script elements illustrate governance policy rules and policy mobility.
// We are a little light on comments here but they are written up in the markdown.
//



//
// Issue a certificate endorsing another principal as "trusted".  We refer to the
// certificate or the statement as an endorsement.
//

defcon endorsement(?Endorsee) :-
{
    trusted($Endorsee).
    label("endorse $Endorsee").
}.

defpost endorse(?Endorsee) :-
   [endorsement(?Endorsee)].

defcon trustPolicySet(?Endorser) :-
{
   endorser($Endorser).
   trustedName(?Name, ?Value) :-
        ?Speaker:nameEntry(?Name, ?Value),
        ?Endorser:trusted(?Speaker),
	endorser(?Endorser).
   label("accept trustedName endorsements from $Endorser").	   
}.

defpost trustPolicy(?Endorser) :-
    [trustPolicySet(?Endorser)].

defcon delegatePolicyAuthoritySet(?PolicyMaker, ?PolicyToken) :-
{
    trustedName(?Name, ?Value) :-
         $PolicyMaker:trustedName(?Name, ?Value).
    link($PolicyToken).
    label("delegate trustedName authority to policy $PolicyToken by maker $PolicyMaker").	   
}.

defpost delegatePolicyAuthority(?PolicyMaker, ?PolicyToken) :-
    [delegatePolicyAuthoritySet(?PolicyMaker, ?PolicyToken)].

defguard queryTrustedName(?Name, ?RootToken, ?Policy) :-
{
   link($RootToken).
   link($Policy).
   trustedName($Name, ?Value)?
}.

defguard queryNameTrustedByPrincipal(?Name, ?Believer, ?RootToken, ?Policy) :-
{
     link($RootToken).
     link($Policy).
     $Believer:trustedName($Name, ?Value)?
}.

