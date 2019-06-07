import("../safe.slang").

//
// Data server (DS)-- Presidio.
//

defguard access(?DataScid, ?U, ?NS, ?Project) :-
   ?DataOwner := rootPrincipal(?DataScid),
   ?DataToken := label(?DataOwner, ?DataScid),
   ?ReceiptRootToken := label(?NS, "receipt root: (?U, ?Project) for ?DataScid"),
{
   link($DataToken).
   link($ReceiptRootToken).

   grantAccess(?Owner, ?DataScid, ?U, ?NS, ?Project) :-
 //  trustedNS(NS),
     ?Owner:access(?DataScid, ?U, ?NS, ?Project).

   grantAccess($DataOwner, $DataScid, $U, $NS, $Project)?
}.




