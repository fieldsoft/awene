-module(passwords).

-export([hash/1, verify/2]).

hash(Pass) ->
    Salt = crypto:strong_rand_bytes(8),
    hash(Pass, Salt).

hash(Pass, Salt) ->
    Key = crypto:pbkdf2_hmac(sha256, Pass, Salt, 10000, 32),
    SaltEncoded = base64:encode(Salt),
    KeyEncoded = base64:encode(Key),
    <<KeyEncoded/binary, $., SaltEncoded/binary>>.

verify(Pass, HashLine) ->
    [_, SaltEncoded] =
        case binary:split(HashLine, <<$.>>, [global]) of
            [_, _] = Split ->
                Split;
            _ ->
                throw({bad_request, <<"Malformed password hash">>})
        end,
    Salt = base64:decode(SaltEncoded),
    HashLine2 = hash(Pass, Salt),
    if
        HashLine2 =:= HashLine ->
            true;
        true ->
            false
    end.
