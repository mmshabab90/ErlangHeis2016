-module (connection).
-compile(export_all).

init() ->
	Hosts = net_adm:host_file(),
	SelfPid = self(), % shit losning, unnskyld Kjetil & Erlang-guder

	PidList = lists:map(fun(Elem) -> spawn_monitor(?MODULE, getNodes, [Elem, SelfPid]) end, Hosts),
	% spawn_monitor returns {Pid, Ref}!!! Shit ensues

	ActiveHosts = list_builder([], PidList),
	net_adm:world_list(ActiveHosts),
	nodes().
	
	%PingResults = lists:map(fun connection:unpackPing/1, NodeList),
	

getNodes(Host, Listener) ->
	timer:exit_after(2000, time_exceeded),
	Message = net_adm:names(Host),
	Listener ! {new_list_item, self(), Host, Message}. %knotete

% unodvendig naa
unpackPing({Name, _Port}) ->
	net_adm:ping(list_to_atom(Name)).


list_builder(HostList, []) ->
	HostList;
list_builder(HostList, PidList) ->
	receive
		{new_list_item, Pid, Host, {ok, _Nodes}} ->
			list_builder([Host | HostList], lists:keydelete(Pid, 1, PidList));
		{new_list_item, Pid, _Host, {error, _Reason}} ->
			list_builder(HostList, lists:keydelete(Pid, 1, PidList));
		{'DOWN', _Ref, process, Pid, _Reason} ->
			list_builder(HostList, lists:keydelete(Pid, 1, PidList))
	end.

	% lager predikat for pid-dropping
	% predikatet funker ikke, pid-lista kortes ikke ned???
	%Pred = fun(DeletePid, {DeletePid, _}) -> true;
	%	(_, _) -> false
	%end,
	%lists:dropwhile(fun(Elem) -> Pred(Pid, Elem) end, PidList)
