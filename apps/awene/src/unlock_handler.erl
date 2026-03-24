-module(unlock_handler).

%% Standard callbacks
-export([
    init/2,
    allowed_methods/2,
    content_types_accepted/2
]).

%% Handler specific callbacks
-export([
    authenticate/2
]).

init(Req, _) ->
    {cowboy_rest, Req, #{}}.

allowed_methods(Req, State) ->
    {[<<"PUT">>], Req, State}.

content_types_accepted(Req, State) ->
    {
        [
            {{<<"application">>, <<"json">>, []}, authenticate}
        ],
        Req,
        State
    }.

authenticate(Req0, State) ->
    {ok, Body, Req} = read_body(Req0, <<>>),
    Json = json:decode(Body),
    case Json of
        #{<<"url">> := Url, <<"username">> := User, <<"password">> := Pass} ->
            case couch:admin_authenticate(User, Pass, Url) of
                true ->
                    Status = set_status(Req, State),
                    {true, cowboy_req:set_resp_body(Status, Req), State};
                _ ->
                    Status = authfailed(),
                    Req1 = cowboy_req:reply(401, #{}, Status, Req),
                    {true, Req1, State}
            end;
        _ ->
            Status = badformat(),
            {false, cowboy_req:set_resp_body(Status, Req), State}
    end.

set_status(Req, #{<<"username">> := User, <<"password">> := Pass, <<"url">> := Url}) ->
    ParsedQs = cowboy_req:parse_qs(Req),
    case proplists:get_value(<<"clear">>, ParsedQs) of
        true ->
            persistent_term:erase(admin_info),
            locked();
        undefined ->
            AdminInfo = #{user => User, pass => Pass, url => Url},
            persistent_term:put(admin_info, AdminInfo),
            unlocked()
    end.

read_body(Req0, Acc) ->
    case cowboy_req:read_body(Req0) of
        {ok, Data, Req} ->
            {ok, <<Acc/binary, Data/binary>>, Req};
        {more, Data, Req} ->
            read_body(Req, <<Acc/binary, Data/binary>>)
    end.

locked() ->
    json:encode(#{<<"status">> => <<"locked">>}).

unlocked() ->
    json:encode(#{<<"status">> => <<"unlocked">>}).

authfailed() ->
    json:encode(#{<<"status">> => <<"auth failed">>}).

badformat() ->
    json:encode(#{<<"status">> => <<"invalid request">>}).
