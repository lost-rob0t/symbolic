:- module(core, [
              entity/1,
              entity_kind/2,
              declare_entity/2,
              entity_label/2,
              entity_alias/2,
              resolve_entity/2,
              kind/1,
              kind_parent/2,
              kind_ancestor/2,
              kind_instance/2,
              now/1,
              iso_now/1,
              time_before/2,
              time_after/2,
              interval_overlaps/2,
              interval_duration/2,
              symbolic_version/1
          ]).

:- use_module(library(apply)).
:- use_module(library(lists)).

symbolic_version('0.1.0').

:- dynamic entity_i/2.
:- dynamic label_i/2.
:- dynamic alias_i/2.

entity(E) :-
    entity_i(E, _).

entity_kind(E, K) :-
    entity_i(E, K).

declare_entity(E, K) :-
    atom(E),
    kind(K),
    (   entity_i(E, K)
    ->  true
    ;   \+ entity_i(E, _OtherKind),
        assertz(entity_i(E, K))
    ).

entity_label(E, L) :-
    label_i(E, L).

entity_alias(E, A) :-
    alias_i(E, A).

resolve_entity(E, E) :-
    entity(E),
    !.
resolve_entity(Alias, E) :-
    entity_alias(E, Alias).

kind(host).
kind(os).
kind(kernel).
kind(device).
kind(filesystem).
kind(actor).
kind(organization).
kind(user_account).
kind(software).
kind(program).
kind(library).
kind(service).
kind(process).
kind(package).
kind(container).
kind(network_interface).
kind(socket).
kind(endpoint).
kind(resource).
kind(artifact).
kind(file).
kind(directory).
kind(artifact_root).
kind(source_file).
kind(test_file).
kind(document).
kind(api).
kind(endpoint_kind).
kind(repository).
kind(branch).
kind(commit).
kind(tag).
kind(event).
kind(observation_kind).
kind(state).
kind(action).
kind(relation).
kind(claim).
kind(fact).
kind(source).
kind(evidence).
kind(identifier).
kind(capability).
kind(policy).
kind(session).
kind(project).
kind(subsystem).
kind(component).
kind(rule).
kind(agent).
kind(extractor).
kind(collector).

kind_parent(os, host).
kind_parent(kernel, host).
kind_parent(program, software).
kind_parent(library, software).
kind_parent(service, software).
kind_parent(process, program).
kind_parent(package, artifact).
kind_parent(file, artifact).
kind_parent(container, software).
kind_parent(source_file, file).
kind_parent(test_file, file).
kind_parent(document, file).
kind_parent(artifact_root, directory).
kind_parent(repository, artifact_root).
kind_parent(branch, artifact).
kind_parent(commit, artifact).
kind_parent(tag, artifact).
kind_parent(endpoint, resource).
kind_parent(socket, resource).
kind_parent(network_interface, device).
kind_parent(subsystem, component).
kind_parent(source_kind, observation_kind).

kind_ancestor(K, K).
kind_ancestor(K, Ancestor) :-
    kind_parent(K, P),
    kind_ancestor(P, Ancestor).

kind_instance(E, AncestorKind) :-
    entity_kind(E, K),
    kind_ancestor(K, AncestorKind).

now(T) :-
    get_time(T).

iso_now(Iso) :-
    get_time(T),
    format_time(atom(Iso), '%FT%TZ', T, posix).

time_before(A, B) :-
    atom(A), atom(B),
    A @< B.

time_after(A, B) :-
    time_before(B, A).

interval_overlaps(interval(S1, E1), interval(S2, E2)) :-
    time_before(S1, E2),
    time_before(S2, E1).

interval_duration(interval(Start, End), Seconds) :-
    (   number(Start)
    ->  S = Start
    ;   parse_time(Start, StampS)
    ->  S = StampS
    ),
    (   number(End)
    ->  E = End
    ;   parse_time(End, StampE)
    ->  E = StampE
    ),
    E >= S,
    Seconds is E - S.
