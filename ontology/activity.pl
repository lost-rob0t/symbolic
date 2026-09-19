:- module(activity, [
              usage_session/4,
              application_session/2,
              afk_interval/1,
              project_activity/3,
              app_of_usage/2,
              activity_source/2
          ]).

:- use_module(core).
:- use_module(provenance).
:- use_module(desktop).

:- dynamic usage_session_i/5.
:- dynamic application_session_i/4.
:- dynamic afk_interval_i/3.
:- dynamic project_activity_i/4.
:- dynamic activity_source_i/2.

usage_session(Device, App, Start, End) :-
    usage_session_i(Device, App, Start, End, _).

application_session(App, interval(Start, End)) :-
    application_session_i(App, Start, End).

afk_interval(interval(Start, End)) :-
    afk_interval_i(Start, End, _).

project_activity(Project, Interval, App) :-
    project_activity_i(Project, Interval, App, _).

app_of_usage(UsageId, App) :-
    usage_session_i(_, App, _, _, UsageId).

activity_source(UsageId, Source) :-
    usage_session_i(_, _, _, _, usage_source(UsageId, Source)).
