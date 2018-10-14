//
// Identity set (apply to all participants)
//

defcon makeMyIdentitySet(?CN) :-
  spec('Construct an identity set for self'),
  {
    principal($SelfKey) :- spec("identity set for $CN").
  }.

defpost postIdSet(?CN) :- [makeMyIdentitySet(?CN)].

defcon makeMyIdentitySetWithPreferredStore(?CN, ?StoreAddr, ?Protocol, ?ServerID) :-
  spec('Construct an identity set for self'),
  {
    principal($SelfKey) :- spec("identity set for $CN").
    preferredSetStore($StoreAddr, $Protocol, $ServerID) :- spec("Preferred stores specified by writer").
  }.

defpost postIdSet(?CN, ?StoreAddr, ?Protocol, ?ServerID) :- 
  [makeMyIdentitySetWithPreferredStore(?CN, ?StoreAddr, ?Protocol, ?ServerID)].

defcon addSetStoreToIDSet(?StoreAddr, ?Protocol, ?ServerID) :-
  spec('Add a set store into identity set'),
  {
    preferredSetStore($StoreAddr, $Protocol, $ServerID).
  }.

defpost updateIDSet(?StoreAddr, ?Protocol, ?ServerID) :- 
  [addSetStoreToIDSet(?StoreAddr, ?Protocol, ?ServerID)].

defcon makeMySubjectSet() :-
  spec("Construct a subject set for self"),
  {
    link($Self).
    label("subject($Self)").
  }.

defpost postSubjectSet() :- [makeMySubjectSet()].

defcon addTokenToSubjectSet(?Token) :- 
  spec("Add a token to the user's subject set."),
  {
    link($Token).
    label("subject($Self)").
  }.
    
defpost updateSubjectSet(?Token) :- [addTokenToSubjectSet(?Token)].
