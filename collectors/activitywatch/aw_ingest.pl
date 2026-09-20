:- module(aw_ingest, [
              ingest_file/1,
              ingested_count/1,
              seen_event/1
          ]).

:- use_module(library(http/json)).
:- use_module(library(lists)).

:- use_module('../../ontology/core').
:- use_module('../../ontology/provenance').
:- use_module('../../ontology/desktop').
:- use_module('../../ontology/activity').

:- dynamic seen_event/1.
:- dynamic ingest_state_i/2.

ingest_file(Path) :-
    setup_call_cleanup(open(Path, read, Stream),
                       read_events(Stream, Events),
                       close(Stream)),
    retractall(ingest_state_i(run_count, _)),
    assertz(ingest_state_i(run_count, 0)),
    forall(member(Event, Events),
           ingest_event(Event)).

ingested_count(Count) :-
    (   ingest_state_i(run_count, Count)
    ->  true
    ;   Count = 0
    ).

read_events(Stream, Events) :-
    catch(json_read_dict(Stream, First),
          error(syntax_error(json(unexpected_end_of_file)), _),
          First = end_of_file),
    (   First == end_of_file
    ->  Events = []
    ;   Events = [First|Rest],
        read_events(Stream, Rest)
    ).

ingest_event(Event) :-
    to_atom(Event.bucket, Bucket),
    Id = Event.event_id,
    Key = aw_event(Bucket, Id),
    (   seen_event(Key)
    ->  true
    ;   ingest_new_event(Event, Key, Bucket, Id)
    ).

ingest_new_event(Event, Key, Bucket, Id) :-
    to_atom(Event.host, Host),
    to_atom(Event.timestamp, Start),
    to_atom(Event.collected_at, CollectedAt),
    to_atom(Event.kind, Kind),
    (   dict_value(Event, duration_s, RawDuration)
    ->  Duration = RawDuration
    ;   Duration = 0.0
    ),
    kind_app(Kind, Event, App),
    event_interval(Start, Duration, End),
    observation_subject(Kind, App, Host, About),
    assert_event_facts(Kind, Bucket, Id, Host, App, Start, End),
    register_observation(Key, Bucket, Kind, About, CollectedAt),
    assertz(seen_event(Key)),
    bump_run_count.

kind_app(window, Event, App) :-
    (   dict_value(Event, app, RawApp)
    ->  to_atom(RawApp, App)
    ;   App = unknown
    ).
kind_app(afk, _, unknown).

observation_subject(window, App, _, App).
observation_subject(afk, _, Host, Host).

dict_value(Dict, Key, Value) :-
    get_dict(Key, Dict, Raw),
    Raw \== null,
    Raw \== @(null),
    Value = Raw.

to_atom(Value, Atom) :-
    (   atom(Value)
    ->  Atom = Value
    ;   string(Value)
    ->  atom_string(Atom, Value)
    ;   term_to_atom(Atom, Value)
    ).

event_interval(Start, Duration, End) :-
    parse_time(Start, Stamp0),
    EndStamp is Stamp0 + Duration,
    stamp_date_time(EndStamp, DateTime, 0),
    format_time(atom(End), '%FT%TZ', DateTime).

assert_event_facts(window, Bucket, Id, Host, App, Start, End) :-
    Key = aw_event(Bucket, Id),
    ensure_application(App, Bucket),
    assertz(activity:application_session_i(App, Start, End,
                                           usage_source(Key, activitywatch))),
    assertz(activity:usage_session_i(Host, App, Start, End,
                                     usage_source(Key, activitywatch))).
assert_event_facts(afk, Bucket, Id, _Host, _App, Start, End) :-
    assertz(activity:afk_interval_i(Start, End, aw_event(Bucket, Id))).

ensure_application(App, Bucket) :-
    (   desktop:application_i(App, _)
    ->  true
    ;   assertz(desktop:application_i(App, aw_bucket(Bucket)))
    ).

register_observation(Key, Bucket, Kind, About, CollectedAt) :-
    register_knowledge(Key, observation,
                       [asserted_by(aw_collector),
                        generator('aw_ingest', '0.1.0'),
                        about(About)]),
    assertz(provenance:observed_by_i(Key, aw_collector)),
    assertz(provenance:observed_at_i(Key, CollectedAt)),
    assertz(provenance:observation_source_i(Key, source(activitywatch, Bucket))),
    assertz(provenance:observation_payload_i(Key, aw_event_kind(Kind))).

bump_run_count :-
    retract(ingest_state_i(run_count, Count0)),
    !,
    Count1 is Count0 + 1,
    assertz(ingest_state_i(run_count, Count1)).
