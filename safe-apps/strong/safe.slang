//
// Identity set (apply to all participants)
//

defcon makeMyIdentitySet(?CN) :-
  spec('Construct an identity set for self'),
  {
    principal($SelfKey) :- spec("identity set for $CN").
  }.

defcon makeMySubjectSet() :-
  spec("Construct a subject set for self"),
  {
    link($Self).
    label("subject($Self)").
  }.

defcon addTokenToSubjectSet(?Token) :- 
  spec("Add a token to the user's subject set."),
  {
    link($Token).
    label("subject($Self)").
  }.

defpost postIdSet(?CN) :- [makeMyIdentitySet(?CN)].
    
defpost postSubjectSet() :- [makeMySubjectSet()].
    
defpost updateSubjectSet(?Token) :- [addTokenToSubjectSet(?Token)]. 
