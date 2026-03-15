-module(jwt_test).

-include_lib("eunit/include/eunit.hrl").
-include_lib("public_key/include/public_key.hrl").

read_pem(File) ->
    {ok, Pem} = file:read_file(File),
    [Entry | _] = public_key:pem_decode(Pem),
    public_key:pem_entry_decode(Entry).

privkey() ->
    read_pem("test/rsa.priv").

pubkey() ->
    read_pem("test/rsa.pub").

header() ->
    #{<<"alg">> => <<"RS256">>, <<"typ">> => <<"JWT">>}.

claims() ->
    #{
        <<"sub">> => <<"niceguy@example.com">>,
        <<"_couchdb.roles">> => [<<"role1">>, <<"role2">>]
    }.

read_pem_test() ->
    ?assertEqual('RSAPrivateKey', element(1, privkey())),
    ?assertEqual('RSAPublicKey', element(1, pubkey())).

encode_test() ->
    Encoded = jwt:encode(header(), claims(), privkey()),
    ?assertMatch({ok, _}, Encoded).

decode_claims_test() ->
    {ok, EncodedToken} = jwt:encode(header(), claims(), privkey()),
    ?assertEqual(claims(), jwt:decode_claims(EncodedToken, pubkey())).
