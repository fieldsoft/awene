-module(jwt).

-export([encode/3, decode_claims/2]).

-include_lib("public_key/include/public_key.hrl").

-spec encode(term(), term(), term()) -> {ok, binary()}.
encode(Header, Claims, Key) ->
    EncodedHeader = base64url:encode(json:encode(Header)),
    EncodedClaims = base64url:encode(json:encode(Claims)),
    Message = <<EncodedHeader/binary, $., EncodedClaims/binary>>,
    Signature = public_key:sign(Message, sha256, Key),
    EncodedSignature = base64url:encode(Signature),
    {ok, <<Message/binary, $., EncodedSignature/binary>>}.

decode_claims(EncodedToken, Key) ->
    [Header, Claims, Signature] = split(EncodedToken),
    Verified = public_key:verify(
        <<Header/binary, $., Claims/binary>>,
        sha256,
        base64url:decode(Signature),
        Key
    ),
    if
        Verified ->
            json:decode(base64url:decode(Claims));
        true ->
            throw({verification, <<"Verification failed">>})
    end.

split(EncodedToken) ->
    case binary:split(EncodedToken, <<$.>>, [global]) of
        [_, _, _] = Split -> Split;
        _ -> throw({bad_request, <<"Malformed token">>})
    end.
