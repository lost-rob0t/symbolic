% Durable knowledge about collectors and the machine-capture pipeline.
% Discovered and verified during the ActivityWatch slice (rage/2-activitywatch).

collector(activitywatch, [
    script('collectors/activitywatch/aw_collect.py'),
    ingest('collectors/activitywatch/aw_ingest.pl'),
    server('aw-server-rust v0.13.2'),
    endpoint('http://127.0.0.1:5600'),
    docs('docs/collectors.org')
]).

aw_wire_format(rust_server, duration(float_seconds)).
aw_wire_format(python_server, duration('H:MM:SS.ffffff')).
aw_wire_format(any_server, duration('ISO8601 PT...')).
aw_wire_format(any_server, event_order(descending_id)).
aw_bucket_kind('aw-watcher-afk_*', afk).
aw_bucket_kind('aw-watcher-window_*', window).
aw_bucket_kind(other_types, skipped).

swi_quirk(format_time_4_posix_is_local,
          'format_time(atom(S), Format, Stamp, posix) formats in LOCAL time on SWI 10.0.2; use stamp_date_time(Stamp, DT, 0) + format_time/3 for UTC.').
swi_quirk(json_eof_throws,
          'json_read_dict/2 throws error(syntax_error(json(unexpected_end_of_file)),_) at EOF instead of returning end_of_file; catch that exact term as EOF.').
swi_quirk(json_values_are_strings,
          'json_read_dict/2 yields JSON strings as SWI strings; atoms must be converted before matching clause heads (e.g. kind_app(window,...)).').
swi_quirk(use_module_relative_from_top,
          'use_module/1 with a relative path from a -g top-level goal resolves against CWD with a deprecation warning; acceptable for Makefile driver goals.').

ontology_gap(application_session_wrapper_arity,
             'activity:application_session/2 queries application_session_i/3 but the declared dynamic predicate is /4 (4th arg = provenance meta); wrapper needs an ontology-slice fix.').

ingest_mapping(aw_event(Bucket, Id),
               [activity:application_session_i(App, Start, End, usage_source(aw_event(Bucket, Id), activitywatch)),
                activity:usage_session_i(Host, App, Start, End, usage_source(aw_event(Bucket, Id), activitywatch)),
                activity:afk_interval_i(Start, End, aw_event(Bucket, Id)),
                desktop:application_i(App, aw_bucket(Bucket))]).
