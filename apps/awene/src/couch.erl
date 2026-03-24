-module(couch).

-export([exists/1, admin_authenticate/3]).

exists(Url) ->
    case hackney:head(Url) of
        {ok, Status, _} ->
            {ok, Status};
        {error, Reason, _} ->
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
