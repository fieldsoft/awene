-module(couch).

-export([exists/0, exists/1, admin_authenticate/3]).

-define(DEFURL, <<"http://127.0.0.1:5984">>).

exists() ->
    exists(?DEFURL).

exists(Url) ->
    case hackney:head(Url) of
        {ok, Status, _} ->
            {ok, Status, Url};
        {error, Reason, Url} ->
            {error, Reason}
    end.

admin_authenticate(User, Pass, Url) ->
    Session = <<Url/binary, "/_session">>,
    Auth = {basic_auth, {User, Pass}},
    Status = hackney:get(Session, [], <<>>, [Auth]),
    case Status of
        {ok, 401, _, _} ->
            false;
        {ok, 200, _Headers, Body} ->
            validate_admin_userctx(User, Body)
    end.

validate_admin_userctx(User, Body) ->
    Json = json:decode(Body),
    case Json of
        #{<<"userCtx">> := UserCtx} ->
            case UserCtx of
                #{<<"name">> := User, <<"roles">> := Roles} ->
                    lists:member(<<"_admin">>, Roles);
                _ ->
                    false
            end;
        _ ->
            false
    end.
