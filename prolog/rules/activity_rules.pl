:- module(activity_rules, []).

:- use_module('../../ontology/core').
:- use_module('../../ontology/provenance').
:- use_module('../../ontology/activity').

:- declare_rule(time_spent_rule,
                time_spent(App, Interval, Duration),
                (   application_session(App, Interval),
                    interval_duration(Interval, Duration)
                )).

:- declare_rule(time_spent_on_project_rule,
                time_spent_on_project(Project, Interval, Duration),
                (   project_activity(Project, Interval, _),
                    interval_duration(Interval, Duration)
                )).
