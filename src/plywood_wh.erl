-module(plywood_wh).

%% Standard callbacks.
-export([init/2]).


init(Req, Opts) ->
	Method = cowboy_req:method(Req),
	HasBody = cowboy_req:has_body(Req),
	Req2 = process(Method, HasBody, Req),
	{ok, Req2, Opts}.

process(<<"GET">>, _Body, Req) ->
	Index = cowboy_req:binding(index, Req),
	Path = cowboy_req:path_info(Req),
	lookup(Index, Path, Req);
process(<<"PUT">>, true, Req) ->
	Index = cowboy_req:binding(index, Req),
	{ok, Data, Req2} = cowboy_req:body(Req, [{length, 100000000}]),
	insert(Index, Data, Req2);
process(<<"PUT">>, false, Req) ->
	cowboy_req:reply(400, [], <<"Missing body.">>, Req);
process(<<"DELETE">>, true, Req) ->
	Index = cowboy_req:binding(index, Req),
	{ok, Data, Req2} = cowboy_req:body(Req, [{length, 100000000}]),
	remove(Index, Data, Req2);
process(<<"DELETE">>, false, Req) ->
	cowboy_req:reply(400, [], <<"Missing body.">>, Req);
process(_, _, Req) ->
	%% Method not allowed.
	cowboy_req:reply(405, Req).

lookup(Index, Path, Req) ->

        try plywood:lookup(Index, Path) of
                Data ->
                        Result = plywood:export(lists:reverse(Path), Data),
                        cowboy_req:reply(200, [
%					{<<"content-type">>, <<"text/json; charset=utf-8">>}
				], jiffy:encode(Result), Req)
        catch
                _Exception:_Reason -> cowboy_req:reply(500, [], <<"Error">>, Req)
        end.

insert(Index, Data, Req) ->
        ok = plywood_worker:add(Index, Data),
	cowboy_req:reply(200, Req).

remove(Index, Data, Req) ->
	ok = plywood_worker:delete(Index, Data),
	cowboy_req:reply(200, Req).