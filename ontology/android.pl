:- module(android, [
              device/1,
              device_model/2,
              device_os/2,
              android_package/1,
              device_event/3,
              device_usage_session/4,
              sync_state/3,
              pending_events/1,
              last_sync/2,
              device_id_of/2
          ]).

:- use_module(core).
:- use_module(provenance).

:- dynamic device_i/3.
:- dynamic device_event_i/4.
:- dynamic device_usage_i/5.
:- dynamic sync_state_i/3.

device(D) :-
    device_i(D, _, _).

device_model(D, M) :-
    device_i(D, M, _).

device_os(D, V) :-
    device_i(D, _, V).

android_package(P) :-
    device_usage_i(_, P, _, _, _).

device_event(D, Kind, Time) :-
    device_event_i(D, Kind, Time, _).

device_usage_session(D, Pkg, Start, End) :-
    device_usage_i(D, Pkg, Start, End, _).

sync_state(D, State, Time) :-
    sync_state_i(D, State, Time).

pending_events(D) :-
    sync_state_i(D, pending, _).

last_sync(D, T) :-
    sync_state_i(D, synced, T).

device_id_of(D, Id) :-
    device_i(D, _, Id).
