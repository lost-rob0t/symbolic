:- module(outcome, [
              attempt/1,
              attempt_expert/2,
              attempt_goal/2,
              attempt_started/2,
              attempt_outcome/2,
              attempt_error_text/2,
              attempt_error_embed/2,
              solution/1,
              solution_signature/2,
              solution_steps/2,
              solution_source/2,
              solution_for_failure/2,
              record_solution/4,
              similar_failure/3,
              suggested_solution/3,
              failure_sim_threshold/1,
              set_failure_threshold/1,
              failure_warnings/3,
              failure_warnings/4,
              failure_warnings/4,
              with_attempt/3
          ]).

:- use_module(library(lists)).
:- use_module('../rlm/tools/embeddings').
:- use_module(core).
:- use_module(provenance).

:- dynamic attempt_i/4.
:- dynamic attempt_outcome_i/3.
:- dynamic solution_i/4.
:- dynamic failure_sim_threshold_i/1.

failure_sim_threshold(0.45).
failure_sim_threshold(T) :-
    failure_sim_threshold_i(T).

set_failure_threshold(T) :-
    number(T),
    T >= 0,
    T =< 1,
    retractall(failure_sim_threshold_i(_)),
    assertz(failure_sim_threshold_i(T)).

active_threshold(T) :-
    (   failure_sim_threshold_i(T)
    ->  true
    ;   failure_sim_threshold(T)
    ).

attempt(A) :-
    attempt_i(A, _, _, _).

attempt_expert(A, E) :-
    attempt_i(A, E, _, _).

attempt_goal(A, G) :-
    attempt_i(A, _, G, _).

attempt_started(A, T) :-
    attempt_i(A, _, _, T).

attempt_outcome(A, success) :-
    attempt_outcome_i(A, outcome(success), _).

attempt_outcome(A, failure) :-
    attempt_outcome_i(A, error(_), _).

attempt_outcome(A, error(E)) :-
    attempt_outcome_i(A, error(E), _).

attempt_error_text(A, Txt) :-
    attempt_outcome_i(A, error(E), _),
    error_text(E, Txt).

attempt_error_embed(A, Emb) :-
    attempt_outcome_i(A, embed(Emb), _).

error_text(T, T) :-
    atom(T),
    !.
error_text(T, Txt) :-
    string(T),
    !,
    atom_string(Txt, T).
error_text(E, Txt) :-
    term_to_atom(E, Txt).

solution(S) :-
    solution_i(S, _, _, _).

solution_signature(S, Sig) :-
    solution_i(S, Sig, _, _).

solution_steps(S, Steps) :-
    solution_i(S, _, Steps, _).

solution_source(S, Src) :-
    solution_i(S, _, _, Src).

solution_for_failure(Sol, A) :-
    attempt_i(A, _, _, _),
    attempt_error_text(A, ErrTxt),
    solution_i(Sol, Sig, _, _),
    sig_overlaps(Sig, ErrTxt).

sig_overlaps(Sig, ErrTxt) :-
    embeddings:tokenize(Sig, SigToks),
    embeddings:tokenize(ErrTxt, ErrToks),
    member(T, SigToks),
    member(T, ErrToks).

record_solution(SigText, StepsText, Source, S) :-
    core:iso_now(Now),
    format(atom(S), 'sol_~w', [Now]),
    assertz(solution_i(S, SigText, StepsText, Source)),
    provenance:register_knowledge(S, claim,
                                  [asserted_by(solution_recorder),
                                   generator(Source, 'outcome-0.1.0'),
                                   confidence(0.7)]).

:- declare_rule(failure_similarity_rule,
                similar_failure(A, B, Sim),
                (   attempt_outcome(A, failure),
                    attempt_error_embed(A, E1),
                    attempt_outcome(B, failure),
                    B \== A,
                    attempt_error_embed(B, E2),
                    cosine(E1, E2, Sim),
                    active_threshold(T),
                    Sim >= T
                )).

:- declare_rule(solution_suggestion_rule,
                suggested_solution(A, Sol, Sim),
                (   similar_failure(A, B, Sim),
                    solution_for_failure(Sol, B)
                )).

similar_failure(A, B, Sim) :-
    attempt_outcome(A, failure),
    attempt_error_embed(A, E1),
    attempt_outcome(B, failure),
    B \== A,
    attempt_error_embed(B, E2),
    cosine(E1, E2, Sim),
    active_threshold(T),
    Sim >= T.

suggested_solution(A, Sol, Sim) :-
    similar_failure(A, B, Sim),
    solution_for_failure(Sol, B).

failure_warnings(ErrorText, Warnings, Solutions) :-
    failure_warnings(ErrorText, none, Warnings, Solutions).

failure_warnings(ErrorText, Exclude, Warnings, Solutions) :-
    embed_text(ErrorText, E),
    active_threshold(T),
    findall(w(Sim, A, Txt),
            (   attempt_outcome(A, failure),
                A \== Exclude,
                attempt_error_embed(A, E2),
                cosine(E, E2, Sim),
                Sim >= T,
                attempt_error_text(A, Txt)
            ),
            Ws0),
    sort(Ws0, Ws1),
    reverse(Ws1, Warnings),
    findall(sol(S, Steps, Src),
            (   member(w(_Sim, B, _), Warnings),
                solution_for_failure(S, B),
                solution_steps(S, Steps),
                solution_source(S, Src)
            ),
            Sols0),
    sort(Sols0, Solutions).

:- meta_predicate with_attempt(+, 0, -).

with_attempt(Expert, Goal, Report) :-
    attempt_begin(Expert, Goal, A),
    (   catch(Goal, Err, true)
    ->  (   var(Err)
        ->  attempt_end(A, success, none),
            Report = outcome_report{attempt: A,
                                    outcome: success,
                                    error: none,
                                    warnings: [],
                                    solutions: []}
        ;   error_text(Err, Txt),
            attempt_end(A, failure, Txt),
            failure_warnings(Txt, A, Warnings, Solutions),
            Report = outcome_report{attempt: A,
                                    outcome: failure,
                                    error: Err,
                                    warnings: Warnings,
                                    solutions: Solutions}
        )
    ;   attempt_end(A, failure, 'goal_failed_without_exception'),
        failure_warnings('goal_failed_without_exception', A, Warnings, Solutions),
        Report = outcome_report{attempt: A,
                                outcome: failure,
                                error: goal_failed,
                                warnings: Warnings,
                                solutions: Solutions}
    ).

:- dynamic attempt_seq_i/1.

attempt_begin(Expert, Goal, A) :-
    core:iso_now(Now),
    (   retract(attempt_seq_i(N0))
    ->  true
    ;   N0 = 0
    ),
    N1 is N0 + 1,
    asserta(attempt_seq_i(N1)),
    format(atom(A), 'att_~w_~w_~w', [Now, N1, Expert]),
    assertz(attempt_i(A, Expert, Goal, Now)).

attempt_end(A, success, _Context) :-
    core:iso_now(Now),
    assertz(attempt_outcome_i(A, outcome(success), Now)),
    provenance:register_knowledge(A, observation, [asserted_by(outcome_tracker)]).
attempt_end(A, failure, ErrorText) :-
    core:iso_now(Now),
    assertz(attempt_outcome_i(A, error(ErrorText), Now)),
    (   catch(embed_text(ErrorText, Emb), _, true)
    ->  assertz(attempt_outcome_i(A, embed(Emb), Now))
    ;   true
    ),
    provenance:register_knowledge(A, observation, [asserted_by(outcome_tracker)]).
