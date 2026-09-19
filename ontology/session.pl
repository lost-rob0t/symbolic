:- module(session, [
              session/1,
              session_kind/2,
              session_project/2,
              session_workdir/2,
              session_started/2,
              session_ended/2,
              session_agent/2,
              session_model/2,
              session_touched_file/2,
              session_commit/2,
              session_summary/2,
              session_error/2,
              session_worked_on/2,
              session_fixed/2,
              session_attempted/2,
              session_discovered/2,
              session_failed_because/2,
              sessions_for_project/2,
              sessions_touching_file/2
          ]).

:- use_module(core).
:- use_module(provenance).
:- use_module(agent_ontology).
:- use_module(source_code).

:- dynamic session_i/2.
:- dynamic session_workdir_i/2.
:- dynamic session_started_i/2.
:- dynamic session_ended_i/2.
:- dynamic session_agent_i/2.
:- dynamic session_model_i/2.
:- dynamic session_touched_i/2.
:- dynamic session_commit_i/2.
:- dynamic session_summary_i/2.
:- dynamic session_error_i/2.
:- dynamic session_worked_i/3.
:- dynamic session_fixed_i/3.
:- dynamic session_attempted_i/3.
:- dynamic session_discovered_i/3.
:- dynamic session_failed_because_i/3.

session(S) :-
    session_i(S, _).

session_kind(S, K) :-
    session_i(S, K).

session_project(S, P) :-
    session_workdir_i(S, Dir),
    project_for_dir(Dir, P).

session_workdir(S, D) :-
    session_workdir_i(S, D).

session_started(S, T) :-
    session_started_i(S, T).

session_ended(S, T) :-
    session_ended_i(S, T).

session_agent(S, A) :-
    session_agent_i(S, A).

session_model(S, M) :-
    session_model_i(S, M).

session_touched_file(S, F) :-
    session_touched_i(S, F).

session_commit(S, C) :-
    session_commit_i(S, C).

session_summary(S, T) :-
    session_summary_i(S, T).

session_error(S, E) :-
    session_error_i(S, E).

session_worked_on(S, What) :-
    session_worked_i(S, What, _).

session_fixed(S, What) :-
    session_fixed_i(S, What, _).

session_attempted(S, What) :-
    session_attempted_i(S, What, _).

session_discovered(S, What) :-
    session_discovered_i(S, What, _).

session_failed_because(S, Cause) :-
    session_failed_because_i(S, Cause, _).

sessions_for_project(Project, S) :-
    session_project(S, Project).

sessions_touching_file(File, S) :-
    session_touched_i(S, File).

project_for_dir(Dir, Project) :-
    source_code:project_i(Project, Dir).
