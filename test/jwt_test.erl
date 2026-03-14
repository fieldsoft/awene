-module(jwt_test).

-include_lib("eunit/include/eunit.hrl").
-include_lib("public_key/include/public_key.hrl").

nada_test() ->
    ?assertMatch(ok, jwt:nada(4)).

%% read_pem_test() ->
%%     {ok, Pem} = file:read_file("test/keys"),
%%     [] = public_key:pem_decode(Pem).
%?assertMatch(ok, public_key:pem_entry_decode(Entry)).
