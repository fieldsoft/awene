%%
%% @doc URL safe base64-compatible codec.
%%
%% Based heavily on the code extracted from:
%%   https://github.com/basho/riak_control/blob/master/src/base64url.erl and
%%   https://github.com/mochi/mochiweb/blob/master/src/mochiweb_base64url.erl.
%%
%% This file taken from:
%%   https://github.com/potatosalad/erlang-base64url/blob/master/src/base64url.erl
%%
%% Copyright (c) 2013 Vladimir Dronnikov dronnikov@gmail.com
%%
%% Permission is hereby granted, free of charge, to any person
%% obtaining a copy of this software and associated documentation
%% files (the "Software"), to deal in the Software without
%% restriction, including without limitation the rights to use, copy,
%% modify, merge, publish, distribute, sublicense, and/or sell copies
%% of the Software, and to permit persons to whom the Software is
%% furnished to do so, subject to the following conditions:
%%
%% The above copyright notice and this permission notice shall be
%% included in all copies or substantial portions of the Software.
%%
%% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
%% EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
%% MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
%% NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
%% BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
%% ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
%% CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
%% SOFTWARE.

-module(base64url).
-author('Vladimir Dronnikov <dronnikov@gmail.com>').

-export([
    decode/1,
    encode/1,
    encode_mime/1
]).

-spec encode(
    binary() | iolist()
) -> binary().

encode(Bin) when is_binary(Bin) ->
    <<<<(urlencode_digit(D))>> || <<D>> <= base64:encode(Bin), D =/= $=>>;
encode(L) when is_list(L) ->
    encode(iolist_to_binary(L)).

-spec encode_mime(
    binary() | iolist()
) -> binary().
encode_mime(Bin) when is_binary(Bin) ->
    <<<<(urlencode_digit(D))>> || <<D>> <= base64:encode(Bin)>>;
encode_mime(L) when is_list(L) ->
    encode_mime(iolist_to_binary(L)).

-spec decode(
    binary() | iolist()
) -> binary().

decode(Bin) when is_binary(Bin) ->
    Bin2 =
        case byte_size(Bin) rem 4 of
            % 1 -> << Bin/binary, "===" >>;
            2 -> <<Bin/binary, "==">>;
            3 -> <<Bin/binary, "=">>;
            _ -> Bin
        end,
    base64:decode(<<<<(urldecode_digit(D))>> || <<D>> <= Bin2>>);
decode(L) when is_list(L) ->
    decode(iolist_to_binary(L)).

urlencode_digit($/) -> $_;
urlencode_digit($+) -> $-;
urlencode_digit(D) -> D.

urldecode_digit($_) -> $/;
urldecode_digit($-) -> $+;
urldecode_digit(D) -> D.
