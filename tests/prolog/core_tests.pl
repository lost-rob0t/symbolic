:- module(core_tests, []).
:- use_module(library(plunit)).
:- use_module('../../ontology/core').

:- begin_tests(core_ontology).

test(declare_entity_and_kind) :-
    declare_entity(flake, host),
    entity(flake),
    entity_kind(flake, host).

test(kind_ancestry_transitive) :-
    once((kind_ancestor(source_file, artifact),
          \+ kind_ancestor(host, artifact))).

test(kind_instance) :-
    declare_entity(readme_md, document),
    once(kind_instance(readme_md, file)).

test(entity_must_have_known_kind) :-
    \+ declare_entity(bogus_entity_1, not_a_kind).

test(alias_resolution) :-
    assertz(core:alias_i(flake, 'home-machine')),
    resolve_entity('home-machine', flake).

test(iso_time_compare) :-
    time_before('2026-09-19T10:00:00Z', '2026-09-19T11:00:00Z'),
    time_after('2026-09-19T11:00:00Z', '2026-09-19T10:00:00Z').

test(interval_duration_iso) :-
    interval_duration(interval('2026-09-19T10:00:00Z', '2026-09-19T10:01:30Z'), D),
    D =:= 90.

test(interval_overlap) :-
    interval_overlaps(interval('2026-01-01T10:00:00Z', '2026-01-01T12:00:00Z'),
                      interval('2026-01-01T11:00:00Z', '2026-01-01T13:00:00Z')),
    \+ interval_overlaps(interval('2026-01-01T10:00:00Z', '2026-01-01T11:00:00Z'),
                         interval('2026-01-01T11:00:00Z', '2026-01-01T12:00:00Z')).

:- end_tests(core_ontology).
