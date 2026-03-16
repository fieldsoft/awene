-module(unlock_handler).

%% Standard callbacks
-export([
    init/2,
    allowed_methods/2,
    content_types_provided/2,
    content_types_accepted/2,
    resource_exists/2
]).

%% Handler specific callbacks
-export([
    authentication_state/2,
    authenticate/2
]).

init(Req, _) ->
    {cowboy_rest, Req, #{}}.

allowed_methods(Req, State) ->
    {[<<"PUT">>, <<"GET">>], Req, State}.

content_types_provided(Req, State) ->
    {
        [
            {<<"application/json">>, authentication_state}
        ],
        Req,
        State
    }.

content_types_accepted(Req, State) ->
    {[{{<<"application">>, <<"json">>, []}, authenticate}], Req, State}.

resource_exists(Req, State) ->
    ParsedQs = cowboy_req:parse_qs(Req),
    Existence =
        case proplists:get_value(<<"url">>, ParsedQs) of
            undefined ->
                couch:exists();
            EncodedUrl ->
                ReqUrl = uri_string:percent_decode(EncodedUrl),
                couch:exists(ReqUrl)
        end,
    case Existence of
        {ok, 200, Url} ->
            {true, Req, State#{<<"url">> => Url}};
        _ ->
            {false, Req, State}
    end.

authentication_state(Req, State) ->
    Locked = json:encode(#{<<"status">> => <<"locked">>}),
    Unlocked = json:encode(#{<<"status">> => <<"unlocked">>}),
    case persistent_term:get(admin_info, undefined) of
        undefined ->
            {Locked, Req, State};
        #{user := User, pass := Pass, url := Url} ->
            Status =
                case couch:admin_authenticate(User, Pass, Url) of
                    true ->
                        Unlocked;
                    _ ->
                        Locked
                end,
            {Status, Req, State}
    end.

authenticate(Req0, State) ->
    {ok, Body, Req} = read_body(Req0, <<>>),
    Json = json:decode(Body),
    #{<<"url">> := Url} = State,
    case Json of
        #{<<"username">> := User, <<"password">> := Pass} ->
            case couch:admin_authenticate(User, Pass, Url) of
                true ->
                    Status = set_status(Json, Req, State),
                    {true, cowboy_req:set_resp_body(Status, Req), State};
                _ ->
                    {false, Req, State}
            end;
        _ ->
            {false, Req, State}
    end.

set_status(#{<<"username">> := User, <<"password">> := Pass}, Req, #{<<"url">> := Url}) ->
    ParsedQs = cowboy_req:parse_qs(Req),
    case proplists:get_value(<<"clear">>, ParsedQs) of
        true ->
            persistent_term:erase(admin_info),
            json:encode(#{<<"status">> => <<"locked">>});
        undefined ->
            AdminInfo = #{user => User, pass => Pass, url => Url},
            persistent_term:put(admin_info, AdminInfo),
            json:encode(#{<<"status">> => <<"unlocked">>})
    end.

read_body(Req0, Acc) ->
    case cowboy_req:read_body(Req0) of
        {ok, Data, Req} ->
            {ok, <<Acc/binary, Data/binary>>, Req};
        {more, Data, Req} ->
            read_body(Req, <<Acc/binary, Data/binary>>)
    end.
