:- module(process_rules, []).

:- use_module('../../ontology/core').
:- use_module('../../ontology/provenance').
:- use_module('../../ontology/computing').
:- use_module('../../ontology/network').

:- declare_rule(port_owner_rule,
                port_owner(Port, Process),
                (   process_listens(Process, Socket),
                    socket_port(Socket, Port)
                )).

:- declare_rule(service_of_process_rule,
                service_of_process(Service, Process),
                (   service_unit(Service, UnitName),
                    process_cmd(Process, Cmd),
                    atom(Cmd),
                    sub_atom(Cmd, _, _, _, UnitName)
                )).
