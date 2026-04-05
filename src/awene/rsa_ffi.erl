-module(rsa_ffi).

-export([sign/2, verify/3]).

-include_lib("public_key/include/public_key.hrl").

-spec sign(binary(), binary()) -> {ok, binary()} | {error, binary()}.
sign(Message, Pem) ->
    try
        [Entry | _] = public_key:pem_decode(Pem),
        Key = public_key:pem_entry_decode(Entry),
        Signature = public_key:sign(Message, sha256, Key),
        {ok, Signature}
    catch
        error:badarg ->
            {error, <<"invalid_der_format">>};
        _:Reason ->
            ErrorBin = list_to_binary(io_lib:format("~p", [Reason])),
            {error, ErrorBin}
    end.

-spec verify(binary(), binary(), binary()) -> {ok, boolean()} | {error, binary()}.
verify(Message, Signature, Pem) ->
    try
        [Entry | _] = public_key:pem_decode(Pem),
        Key = public_key:pem_entry_decode(Entry),
        Verified = public_key:verify(Message, sha256, Signature, Key),
        {ok, Verified}
    catch
        error:badarg ->
            {error, <<"invalid_der_format">>};
        _:Reason ->
            ErrorBin = list_to_binary(io_lib:format("~p", [Reason])),
            {error, ErrorBin}
    end.
