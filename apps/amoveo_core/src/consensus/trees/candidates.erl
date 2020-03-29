-module(candidates).
-export([new/9,
	 write/2, get/2, delete/2,%update tree stuff
         dict_update/2, dict_delete/2, dict_write/2, dict_get/2,%update dict stuff
         verify_proof/4, make_leaf/3, key_to_int/1, 
	 deserialize/1, serialize/1, 
	 all/0,
         id/1, sortition_id/1, layer_number/1, winner/1, winner2/1, height/1, next_candidate/1,
         recovery_spend/1, contracts_root/1,
         test/0
]).
-define(id, candidates).
-include("../../records.hrl").
%-record(candidate, {id, sortition_id, layer_number, winner, winner2, recovery_spend, height, priority, next_candidate}).%merkle tree


new(ID, SID, N, WP, W2, H, Pr, NC, CR) ->
    #candidate{
     id = ID,
     sortition_id = SID,
     layer_number = N,
     winner = WP,
     winner2 = W2,
     recovery_spend = <<0:520>>,
     height = H,
     priority = Pr, 
     next_candidate = NC,
     contracts_root = CR
    }.

id(C) -> C#candidate.id.
sortition_id(C) -> C#candidate.sortition_id.
layer_number(C) -> C#candidate.layer_number.
winner(C) -> C#candidate.winner.
winner2(C) -> C#candidate.winner2.
recovery_spend(C) -> C#candidate.recovery_spend.
height(C) -> C#candidate.height.
next_candidate(C) -> C#candidate.next_candidate. 
contracts_root(C) -> C#candidate.contracts_root. 

write(C, Root) ->
    Key = C#candidate.id,
    SC = serialize(C),
    ID = key_to_int(Key),
    trie:put(ID, SC, 0, Root, ?id).

get(Key, Candidate) ->
    ID = key_to_int(Key),
    {RH, Leaf, Proof} = trie:get(ID, Candidate, ?id),
    S = case Leaf of
            empty -> empty;
            Leaf ->
                deserialize(leaf:value(Leaf))
        end,
    {RH, S, Proof}.
    

delete(Key, Sortition) ->
    ID = key_to_int(Key),
    trie:delete(ID, Sortition, ?id).

dict_update(C, NC) ->
    C#candidate{
      next_candidate = NC
     }.

dict_delete(Key, Dict) ->
    dict:store({candidates, Key}, 0, Dict).

dict_write(C, Dict) ->
    K = id(C),
    dict:store({candidates, K},
               serialize(C), 
               Dict).

dict_get(Key, Dict) ->
    case dict:find({candidates, Key}, Dict) of
	error -> empty;
        {ok, 0} -> empty;
        {ok, empty} -> empty;
        {ok, Y} -> deserialize(Y)
    end.

verify_proof(RootHash, Key, Value, Proof) ->
    trees:verify_proof(?MODULE, RootHash, Key, Value, Proof).

make_leaf(Key, V, CFG) ->
    leaf:new(key_to_int(Key), V, 0, CFG).

key_to_int(X) -> 
    <<_:256>> = X,
    <<Y:256>> = hash:doit(X),
    Y.

serialize(C) ->
%-record(candidate, {id, sortition_id, layer_number, winner_pubkey, height, next_candidate}).%merkle tree
    HS = constants:hash_size(),
    PS = constants:pubkey_size(),
    BAL = constants:balance_bits(),
    HEI = constants:height_bits(),
    ID = C#candidate.id,
    HS = size(ID),
    SI = C#candidate.sortition_id,
    HS = size(SI),
    Winner = C#candidate.winner,
    Winner2 = C#candidate.winner2,
    RecoverySpend = C#candidate.recovery_spend,
    PS = size(Winner),
    PS = size(Winner2),
    NC = C#candidate.next_candidate,
    CR = C#candidate.contracts_root,
    HS = size(NC),
    HS = size(CR),
    <<ID/binary,
      SI/binary,
      (C#candidate.layer_number):16,
      Winner/binary,
      Winner2/binary,
      RecoverySpend/binary,
      (C#candidate.height):HEI,
      (C#candidate.priority):8,
      NC/binary,
      CR/binary>>.
      
deserialize(B) ->
    HS = constants:hash_size()*8,
    PS = constants:pubkey_size()*8,
    HEI = constants:height_bits(),
    <<
      ID:HS,
      SI:HS,
      LN:16,
      Winner:PS,
      Winner2:PS,
      RecoverySpend:PS,
      Height:HEI,
      Priority:8,
      NC:HS,
      CR:HS
    >> = B,
    #candidate{
           id = <<ID:HS>>,
           sortition_id = <<SI:HS>>,
           layer_number = LN,
           winner = <<Winner:PS>>,
           winner2 = <<Winner2:PS>>,
           recovery_spend = <<RecoverySpend:PS>>,
           height = Height,
           priority = Priority,
           next_candidate = <<NC:HS>>,
           contracts_root = <<CR:HS>>
          }.

all() ->
    Trees = (tx_pool:get())#tx_pool.block_trees,
    Sortition = trees:?MODULE(Trees),
    All = trie:get_all(Sortition, ?MODULE),
    lists:map(fun(X) ->
                      deserialize(leaf:value(X))
              end, All).

test() ->
    %make a new.
    {Pub, _Priv} = testnet_sign:new_key(),
    ID = hash:doit(1),
    S = new(ID,
            hash:doit(2),
            1,
            Pub,
            <<0:520>>,
            1,
            0,
            hash:doit(3),
            hash:doit(4)),
    %serialize deserialize
    S1 = deserialize(serialize(S)),
    %io:fwrite([S, S1]),
    S = S1,
    %make an empty tree.
    Root0 = trees:empty_tree(candidates),
    %write to the tree.
    NewLoc = write(S, Root0),
    %verify a proof.
    {Root, S, Proof} = get(ID, NewLoc),
    true = verify_proof(Root, ID, serialize(S), Proof),
    {Root2, empty, Proof2} = get(ID, Root0),
    true = verify_proof(Root2, ID, 0, Proof2),
    success.
