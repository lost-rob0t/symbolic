:- module(computing, [
              host/1,
              os/1,
              kernel/1,
              software/1,
              program/1,
              library/1,
              service/1,
              process/1,
              package/1,
              runs_on/2,
              software_provider/2,
              service_unit/2,
              service_state/3,
              process_exe/2,
              process_cmd/2,
              process_parent/2,
              process_user/2,
              process_cwd/2,
              process_start/2,
              process_listens/2,
              package_version/3,
              package_manager/2,
              package_owns/2,
              installed_at/2
          ]).

:- use_module(core).
:- use_module(provenance).

:- dynamic runs_on_i/2.
:- dynamic software_provider_i/2.
:- dynamic service_unit_i/2.
:- dynamic service_state_i/3.
:- dynamic process_exe_i/2.
:- dynamic process_cmd_i/2.
:- dynamic process_parent_i/2.
:- dynamic process_user_i/2.
:- dynamic process_cwd_i/2.
:- dynamic process_start_i/2.
:- dynamic process_listens_i/2.
:- dynamic package_version_i/3.
:- dynamic package_manager_i/2.
:- dynamic package_owns_i/2.
:- dynamic installed_at_i/2.

host(H) :-
    core:kind_instance(H, host).

os(O) :-
    core:entity_kind(O, os).

kernel(K) :-
    core:entity_kind(K, kernel).

software(S) :-
    core:kind_instance(S, software).

program(P) :-
    core:entity_kind(P, program).

library(L) :-
    core:entity_kind(L, library).

service(S) :-
    core:entity_kind(S, service).

process(P) :-
    core:entity_kind(P, process).

package(P) :-
    core:entity_kind(P, package).

runs_on(Software, Host) :-
    runs_on_i(Software, Host).

software_provider(S, Provider) :-
    software_provider_i(S, Provider).

service_unit(Service, Unit) :-
    service_unit_i(Service, Unit).

service_state(Service, State, Time) :-
    service_state_i(Service, State, Time).

process_exe(P, Exe) :-
    process_exe_i(P, Exe).

process_cmd(P, Cmd) :-
    process_cmd_i(P, Cmd).

process_parent(P, Parent) :-
    process_parent_i(P, Parent).

process_user(P, User) :-
    process_user_i(P, User).

process_cwd(P, Dir) :-
    process_cwd_i(P, Dir).

process_start(P, T) :-
    process_start_i(P, T).

process_listens(P, Socket) :-
    process_listens_i(P, Socket).

package_version(P, V, T) :-
    package_version_i(P, V, T).

package_manager(P, M) :-
    package_manager_i(P, M).

package_owns(P, File) :-
    package_owns_i(P, File).

installed_at(P, T) :-
    installed_at_i(P, T).
