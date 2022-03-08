### poor men's cluster leader

This runner (invoked via a schedule on salt master) checks consul for the current cluster
leader and sets the runtime option "set_leader" to the leading master server.

Usefull in multi master scenarios where the minion cache is set to consul and
the salt masters itself are consul members.

This runner prevents parallel reactors to be fired by minions connected to
multiple masters.
