-module(base64url_test).

-include_lib("eunit/include/eunit.hrl").

aim_test() ->
    % vanilla base64 produce URL unsafe output
    ?assertNotEqual(
        binary:match(base64:encode([255, 127, 254, 252]), [<<"=">>, <<"/">>, <<"+">>]),
        nomatch
    ),
    % this codec produce URL safe output
    ?assertEqual(
        binary:match(base64url:encode([255, 127, 254, 252]), [<<"=">>, <<"/">>, <<"+">>]),
        nomatch
    ),
    % the mime codec produces URL unsafe output, but only because of padding
    ?assertEqual(
        binary:match(base64url:encode_mime([255, 127, 254, 252]), [<<"/">>, <<"+">>]),
        nomatch
    ),
    ?assertNotEqual(
        binary:match(base64url:encode_mime([255, 127, 254, 252]), [<<"=">>]),
        nomatch
    ).

codec_test() ->
    % codec is lossless with or without padding
    ?assertEqual(base64url:decode(base64url:encode(<<"foo">>)), <<"foo">>),
    ?assertEqual(base64url:decode(base64url:encode(<<"foo1">>)), <<"foo1">>),
    ?assertEqual(base64url:decode(base64url:encode(<<"foo12">>)), <<"foo12">>),
    ?assertEqual(base64url:decode(base64url:encode(<<"foo123">>)), <<"foo123">>),
    ?assertEqual(base64url:decode(base64url:encode_mime(<<"foo">>)), <<"foo">>),
    ?assertEqual(base64url:decode(base64url:encode_mime(<<"foo1">>)), <<"foo1">>),
    ?assertEqual(base64url:decode(base64url:encode_mime(<<"foo12">>)), <<"foo12">>),
    ?assertEqual(base64url:decode(base64url:encode_mime(<<"foo123">>)), <<"foo123">>).

iolist_test() ->
    % codec supports iolists
    ?assertEqual(base64url:decode(base64url:encode("foo")), <<"foo">>),
    ?assertEqual(base64url:decode(base64url:encode(["fo", "o1"])), <<"foo1">>),
    ?assertEqual(base64url:decode(base64url:encode([255, 127, 254, 252])), <<255, 127, 254, 252>>),
    ?assertEqual(base64url:decode(base64url:encode_mime("foo")), <<"foo">>),
    ?assertEqual(base64url:decode(base64url:encode_mime(["fo", "o1"])), <<"foo1">>),
    ?assertEqual(
        base64url:decode(base64url:encode_mime([255, 127, 254, 252])), <<255, 127, 254, 252>>
    ).
