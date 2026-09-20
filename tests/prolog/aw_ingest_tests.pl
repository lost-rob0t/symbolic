:- module(aw_ingest_tests, []).
:- use_module(library(plunit)).
:- use_module(library(apply)).
:- use_module(library(lists)).
:- use_module('../../ontology/core').
:- use_module('../../ontology/provenance').
:- use_module('../../ontology/desktop').
:- use_module('../../ontology/activity').
:- use_module('../../collectors/activitywatch/aw_ingest').

:- prolog_load_context(source, Src),
   file_directory_name(Src, Dir),
   assertz(fixture_dir_i(Dir)).

fixture(Path) :-
    fixture_dir_i(Dir),
    atomic_list_concat([Dir, '/../fixtures/aw_sample.jsonl'], Path).

aw_keys([aw_event('aw-watcher-window_testbox', 1),
         aw_event('aw-watcher-window_testbox', 2),
         aw_event('aw-watcher-afk_testbox', 3),
         aw_event('aw-watcher-window_testbox', 4)]).

cleanup_aw :-
    aw_keys(Keys),
    forall(member(Key, Keys), cleanup_key(Key)),
    forall(member(App, [emacs, firefox]),
           retractall(desktop:application_i(App, _))),
    retractall(aw_ingest:seen_event(_)),
    retractall(aw_ingest:ingest_state_i(_, _)).

cleanup_key(Key) :-
    retractall(provenance:knowledge_i(Key, _)),
    retractall(provenance:asserted_at_i(Key, _)),
    retractall(provenance:asserted_by_i(Key, _)),
    retractall(provenance:generator_i(Key, _, _)),
    retractall(provenance:observation_of_i(Key, _)),
    retractall(provenance:observed_by_i(Key, _)),
    retractall(provenance:observed_at_i(Key, _)),
    retractall(provenance:observation_source_i(Key, _)),
    retractall(provenance:observation_payload_i(Key, _)),
    retractall(activity:application_session_i(_, _, _, usage_source(Key, activitywatch))),
    retractall(activity:usage_session_i(_, _, _, _, usage_source(Key, activitywatch))),
    retractall(activity:afk_interval_i(_, _, Key)).

count_application_sessions(Count) :-
    aggregate_all(count,
                  activity:application_session_i(_, _, _,
                                                 usage_source(_, activitywatch)),
                  Count).

count_usage_sessions(Count) :-
    aggregate_all(count,
                  activity:usage_session_i(_, _, _, _, usage_source(_, activitywatch)),
                  Count).

count_afk_intervals(Count) :-
    aggregate_all(count, activity:afk_interval_i(_, _, aw_event(_, _)), Count).

count_observations(Count) :-
    aggregate_all(count,
                  (   aw_ingest_tests:aw_keys(Keys),
                      member(Key, Keys),
                      provenance:epistemic_status(Key, observation)
                  ),
                  Count).

:- begin_tests(aw_ingest).

test(ingest_projects_ontology_facts, [setup(cleanup_aw)]) :-
    fixture(Path),
    aw_ingest:ingest_file(Path),
    aw_ingest:ingested_count(4),
    count_application_sessions(3),
    count_usage_sessions(3),
    count_afk_intervals(1),
    count_observations(4).

test(ingest_twice_dedupes_on_event_id) :-
    fixture(Path),
    aw_ingest:ingest_file(Path),
    aw_ingest:ingested_count(0),
    count_application_sessions(3),
    count_usage_sessions(3),
    count_afk_intervals(1),
    aggregate_all(count, aw_ingest:seen_event(_), 4).

test(provenance_edges_exist) :-
    Key = aw_event('aw-watcher-window_testbox', 1),
    provenance:epistemic_status(Key, observation),
    provenance:asserted_by(Key, aw_collector),
    provenance:generator(Key, 'aw_ingest', '0.1.0'),
    provenance:asserted_at(Key, _),
    provenance:observed_by(Key, aw_collector),
    provenance:observed_at(Key, '2026-09-19T09:05:00Z'),
    provenance:observation_source(Key,
                                  source(activitywatch,
                                         'aw-watcher-window_testbox')),
    provenance:observation_payload(Key, aw_event_kind(window)),
    provenance:observation_of(Key, emacs).

test(application_session_derived_facts) :-
    Key = usage_source(aw_event('aw-watcher-window_testbox', 1), activitywatch),
    activity:application_session_i(emacs, '2026-09-19T09:00:00Z',
                                   '2026-09-19T09:05:00Z', Key),
    activity:app_of_usage(Key, emacs),
    activity:activity_source(aw_event('aw-watcher-window_testbox', 1),
                             activitywatch),
    activity:usage_session(testbox, emacs, '2026-09-19T09:00:00Z',
                           '2026-09-19T09:05:00Z'),
    desktop:application(emacs),
    desktop:application_i(emacs, aw_bucket('aw-watcher-window_testbox')),
    desktop:application(firefox),
    \+ desktop:application_i(emacs, aw_bucket(other)).

test(afk_interval_derived_facts, [cleanup(cleanup_aw)]) :-
    activity:afk_interval_i('2026-09-19T09:06:00Z', '2026-09-19T09:08:00Z',
                            aw_event('aw-watcher-afk_testbox', 3)),
    activity:afk_interval(interval('2026-09-19T09:06:00Z',
                                   '2026-09-19T09:08:00Z')).

:- end_tests(aw_ingest).
