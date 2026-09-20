:- module(debug_rules, []).

:- use_module(library(lists)).
:- use_module('../../ontology/core').
:- use_module('../../ontology/provenance').
:- use_module('../../ontology/computing').
:- use_module('../../ontology/session').
:- use_module('../../ontology/documentation').

:- declare_rule(candidate_cause_service_rule,
                candidate_cause(Subject, broken_service(State, Time), service_state(Subject, State, Time)),
                (   computing:service_state(Subject, State, Time),
                    member(State, [failed, failed_to_start, crashed, inactive_dead])
                )).

:- declare_rule(candidate_cause_package_rule,
                candidate_cause(Subject, recent_package_change(Package, Installed), package_owns(Package, Path)),
                (   computing:package_owns(Package, Path),
                    subject_matches_path(Subject, Path),
                    computing:package_version(Package, _, Installed),
                    core:iso_now(Now),
                    core:time_before(Installed, Now),
                    core:interval_duration(interval(Installed, Now), D),
                    D =< 604800
                )).

:- declare_rule(candidate_cause_session_rule,
                candidate_cause(Subject, prior_failed_session(S, Cause), session_failed(S, Cause)),
                (   session:session_failed_because(S, Cause),
                    session_about(S, Subject)
                )).

:- declare_rule(candidate_cause_docs_rule,
                candidate_cause(Subject, configuration_documentation_gap(Doc), doc_section(Doc, Title, _)),
                (   documentation:doc_section(Doc, Title, _),
                    atom(Title),
                    downcase_atom(Title, DT),
                    downcase_atom(Subject, DS),
                    sub_atom(DT, _, _, _, DS)
                )).

subject_matches_path(Subject, Path) :-
    atom(Path),
    downcase_atom(Path, DP),
    downcase_atom(Subject, DS),
    sub_atom(DP, _, _, _, DS).

session_about(S, Subject) :-
    session:session_workdir(S, Dir),
    atom(Dir),
    downcase_atom(Dir, DD),
    downcase_atom(Subject, DS),
    sub_atom(DD, _, _, _, DS).
session_about(S, Subject) :-
    session:session_summary(S, Summary),
    atom(Summary),
    downcase_atom(Summary, DSum),
    downcase_atom(Subject, DS2),
    sub_atom(DSum, _, _, _, DS2).
