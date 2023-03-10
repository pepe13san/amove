-module(txs).
-export([digest/3, developer_lock/3, key2module/1, txid/1]).
txid(T) ->
    T2 = case element(1, T) of
             signed -> signing:data(T);
             _ -> T
         end,
    hash:doit(T2).
digest([C|T], Dict, H) ->
    case element(1, C) of
        coinbase ->
            NewDict = coinbase_tx:go(C, Dict, H),
            digest_txs(T, NewDict, H);
        signed -> digest_txs([C|T], Dict, H)
    end.
digest_txs([], Dict, _) -> Dict;
digest_txs([STx|T], Dict, Height) ->
    case application:get_env(amoveo_core, assume_valid) of
        {ok, {AssumeHeight, _}} ->
            if
                (AssumeHeight > Height) -> ok;
                true -> true = signing:verify(STx)
            end;
        _ ->
            %no assume_valid block in the config file.
            true = signing:verify(STx)
    end,
    Tx = signing:data(STx),
    Fee = element(4, Tx),
    true = Fee > 0,
    Key = element(1, Tx),
    M = key2module(Key),
    NewDict = M:go(Tx, Dict, Height, true),
    digest_txs(T, NewDict, Height).
key2module(multi_tx) -> multi_tx;
key2module(create_acc_tx) -> create_account_tx;
key2module(spend) -> spend_tx;
key2module(delete_acc_tx) -> delete_account_tx;
key2module(nc) -> new_channel_tx;
key2module(nc_accept) -> new_channel_tx2;
key2module(ctc) -> channel_team_close_tx;
key2module(ctc2) -> channel_team_close_tx2;
key2module(csc) -> channel_solo_close;
key2module(timeout) -> channel_timeout_tx;
key2module(cs) -> channel_slash_tx;
key2module(ex) -> existence_tx;
key2module(oracle_new) -> oracle_new_tx;
key2module(oracle_bet) -> oracle_bet_tx;
key2module(oracle_close) -> oracle_close_tx;
key2module(unmatched) -> oracle_unmatched_tx;
key2module(oracle_winnings) -> oracle_winnings_tx;
key2module(contract_new_tx) -> contract_new_tx;
key2module(stablecoin_new_tx) -> stablecoin_new_tx;
key2module(contract_use_tx) -> contract_use_tx;
key2module(sub_spend_tx) -> sub_spend_tx;
key2module(contract_evidence_tx) -> contract_evidence_tx;
key2module(contract_timeout_tx) -> contract_timeout_tx;
key2module(contract_timeout_tx2) -> contract_timeout_tx2;
key2module(contract_winnings_tx) -> contract_winnings_tx;
key2module(contract_simplify_tx) -> contract_simplify_tx;
key2module(swap_tx) -> swap_tx;
key2module(swap_tx2) -> swap_tx2;
key2module(market_new_tx) -> market_new_tx;
key2module(market_liquidity_tx) -> market_liquidity_tx;
key2module(market_swap_tx) -> market_swap_tx;
key2module(trade_cancel_tx) -> trade_cancel_tx;
key2module(coinbase_old) -> coinbase_tx.
developer_lock(From, NewHeight, Dict) -> ok.
%case application:get_env(amoveo_core, kind) of
%	{ok, "production"} -> ok;
	    %Burn = base64:decode("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEFAx4lA9qJP3/x4hz1EkNIQAAAAAAAAA="),
        %Burn = constants:burn_address(),
	%    false = (From == Burn);
	    %MP = constants:master_pub(),
	    %if
		%From == MP ->
		%    BP = governance:dict_get_value(block_period, Dict),
		%    HeightSwitch = (10 * constants:developer_lock_period()) div BP,
		%    true = NewHeight > HeightSwitch;
		%true -> ok
	    %end;
%	_ -> ok
%    end.
    
