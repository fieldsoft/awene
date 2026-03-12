-module(hello_handler).
-behavior(cowboy_handler).

-export([init/2]).

init(Req0, State) ->
    Req = cowboy_req:reply(200,
        #{<<"Content-Type">> => <<"text/plain">>},
        <<"Hello Erlang!">>,
        Req0),
    {ok, Req, State}.
