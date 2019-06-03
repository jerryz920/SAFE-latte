
//
// Demonstrates linking and labeling.
// Run this in a SAFE engine and hit it with curls or slang-shell.
// It has primitives to build chains of logical certificates using synthesized links,
// and check that specific certs/statements are present in the chains.
//

import("../safe-client.slang").


defenv ServerJVM() :- "localhost:7777".
defenv ReqEnvs() :- ":::".

//
// Create a basic labeled (named) logic set.  Returns a token.
// This logic set/cert has zero links so we call it an "anchor".
//

defcall dropAnchor(?Name) :-
{
   dropAnchor($ServerJVM, $ReqEnvs, $Name).
}.

//
// Create a labeled logic set that links (includes) another set by token.
// For this variant the issuer of the target could be $Self or anyone.
// E.g.,  the issuer might pass the token to the caller out-of-band and the
// caller passes the token in to link to the target cert.
//

defcall dropLink(?Name, ?PrevToken) :-
{
   dropLink($ServerJVM, $ReqEnvs, $Name, $PrevToken).
}.

defcall cons(?CarToken, ?CdrToken) :-
{
    postCell($ServerJVM, $ReqEnvs, $CarToken, $CdrToken)
}.

//
// Create a labeled logic set that links (includes) another set by name.
// This variant presumes that the link target is a cert issued by $Self.
//

defcall dropLinkByName(?Name, ?PrevName) :-
{
   dropLinkByName($ServerJVM, $ReqEnvs, $Name, $PrevName).
}.

//
// Create a labeled logic set that links (includes) another set by name.
// For this variant the issuer of the target could be Self or anyone.
//

defcall dropCrossLinkByName(?Name, ?PrevName, ?Owner) :-
{
   dropCrossLinkByName($ServerJVM, $ReqEnvs, $Name, $PrevName, $Owner).
}.

//
// Check to see if a name is present in a linked set (chain) rooted in a token.
// (According to a specified issuer who issued the cert with that name.)
// This demonstrates a query against logic statements spoken by another party.
//

defcall present(?Name, ?Owner, ?RootToken) :-
{
   queryPresent($ServerJVM, $ReqEnvs, $Name, $Owner, $RootToken).
}.

//
// Check to see if a name is present in a linked set (chain) rooted in a named set.
// (According to a specific issuer who issued the cert with that name.)
//

defcall presentByName(?Name, ?Owner, ?RootName, ?RootOwner) :-
{
   queryPresentByName($ServerJVM, $ReqEnvs, $Name, $Owner, $RootName, $RootOwner).
}.

defcall endorse(?Endorsee) :-
{
   endorse($ServerJVM, $ReqEnvs, $Endorsee).
}.

defcall trustPolicy(?Endorser) :-
{
   trustPolicy($ServerJVM, $ReqEnvs, $Endorser).
}.


defcall delegatePolicyAuthority(?PolicyMaker, ?PolicyToken) :-
{
   delegatePolicyAuthority($ServerJVM, $ReqEnvs, $PolicyMaker, $PolicyToken).
}.
  

defcall queryTrustedName(?Name, ?RootToken, ?Policy) :-
{
    queryTrustedName($ServerJVM, $ReqEnvs, $Name, $RootToken, $Policy).
}.


defcall queryNameTrustedByPrincipal(?Name, ?Believer, ?RootToken, ?Policy) :-
{
    queryNameTrustedByPrincipal($ServerJVM, $ReqEnvs, $Name, $Believer, $RootToken, $Policy).
}.


//
// Check to see if a name is present in a linked set (chain) rooted in a token.
// This variant "believes" that name is present only if "I said it", i.e., Self
// is the issuer of a certificate with that name in the chain.
//
// XXX I don't see why this won't parse.
// safe.safelog.ParserException: Unsound rule dectected. Check range restriction failed 
//
//defcall inhere(?Name, ?RootToken) :-
//{
//  queryInHere($ServerJVM, $ReqEnvs, $Name, $RootToken).
//}.




