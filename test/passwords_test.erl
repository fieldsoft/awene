-module(passwords_test).

-include_lib("eunit/include/eunit.hrl").

verify_test() ->
    Hash = passwords:hash(<<"neverguess">>),
    ?assert(passwords:verify(<<"neverguess">>, Hash)).
