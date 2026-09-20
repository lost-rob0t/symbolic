:- module(network, [
              interface/1,
              interface_addr/3,
              listening_socket/2,
              socket_port/2,
              socket_proto/2,
              local_endpoint/2,
              service_endpoint/2,
              established_to/2
          ]).

:- use_module(core).
:- use_module(provenance).
:- use_module(computing).

:- dynamic interface_i/2.
:- dynamic interface_addr_i/3.
:- dynamic listening_socket_i/2.
:- dynamic local_endpoint_i/2.
:- dynamic service_endpoint_i/2.
:- dynamic established_to_i/2.

interface(I) :-
    interface_i(I, _).

interface_addr(I, Addr, Family) :-
    interface_addr_i(I, Addr, Family).

listening_socket(P, Socket) :-
    listening_socket_i(P, Socket).

socket_port(Socket, Port) :-
    socket_port_i(Socket, Port).

socket_proto(Socket, Proto) :-
    socket_proto_i(Socket, Proto).

local_endpoint(Socket, endpoint(Addr, Port)) :-
    socket_addr_i(Socket, Addr),
    socket_port_i(Socket, Port).

service_endpoint(Service, endpoint(Addr, Port)) :-
    service_endpoint_i(Service, endpoint(Addr, Port)).

established_to(P, Remote) :-
    established_to_i(P, Remote).

:- dynamic socket_port_i/2.
:- dynamic socket_addr_i/2.
:- dynamic socket_proto_i/2.
