%%%-------------------------------------------------------------------
%% @doc awene public API
%% @end
%%%-------------------------------------------------------------------

-module(awene_app).

-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    awene_sup:start_link().

stop(_State) ->
    ok.

%% internal functions
