-module(jwt).

-export([encode/3, nada/1]).

-include_lib("public_key/include/public_key.hrl").

-spec encode(term(), term(), term()) -> {ok, binary()}.
encode(Header, Claims, Key) ->
    EncodedHeader = base64url:encode(json:encode(Header)),
    EncodedClaims = base64url:encode(json:encode(Claims)),
    Message = <<EncodedHeader/binary, $., EncodedClaims/binary>>,
    Signature = public_key:sign(Message, sha256, Key),
    EncodedSignature = base64url:encode(Signature),
    {ok, <<Message/binary, $., EncodedSignature/binary>>}.

nada(_) ->
    ok.
