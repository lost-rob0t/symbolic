:- module(outcome_tests, []).
:- use_module(library(plunit)).
:- use_module('../../ontology/core').
:- use_module('../../ontology/provenance').
:- use_module('../../ontology/outcome').
:- use_module('../../rlm/tools/embeddings').

:- begin_tests(embeddings).

test(tokenize) :-
    tokenize('Emacs-Daemon failed!', T),
    member(emacs, T),
    member(daemon, T),
    member(failed, T).

test(embed_nonempty_normalized) :-
    embed_text('emacs daemon failed to start', E),
    E \= [],
    embeddings:cosine(E, E, Sim),
    Sim > 0.99.

test(similar_texts_score_higher) :-
    embed_text('emacs daemon failed to start', E1),
    embed_text('emacs daemon crashed on start', E2),
    embed_text('qtile bar widget colors', E3),
    cosine(E1, E2, SimClose),
    cosine(E1, E3, SimFar),
    SimClose > SimFar.

test(cosine_self_one) :-
    embed_text('service failed', E),
    cosine(E, E, 1.0).

:- end_tests(embeddings).

:- begin_tests(outcomes).

test(success_attempt_tracked) :-
    with_attempt(test_expert, true, Report),
    Report = outcome_report(A, success, _ErrS, _WS, _SS),
    attempt(A),
    attempt_outcome(A, success),
    provenance:asserted_by(A, outcome_tracker),
    provenance:epistemic_status(A, observation).

test(failure_attempt_tracked_with_embed) :-
    with_attempt(test_expert, throw(emacs_daemon_failed_to_start), Report),
    Report = outcome_report(A, failure, ErrF, _WF, _SF),
    ErrF \= none,
    attempt_error_text(A, Txt),
    atom(Txt),
    attempt_error_embed(A, E),
    E \= [].

test(similar_failure_detected_via_rule) :-
    with_attempt(test_expert, throw(emacs_daemon_failed_to_start), _R1),
    with_attempt(test_expert, throw(emacs_daemon_failed_on_start), R2),
    R2 = outcome_report(A2, failure, _E2, _W2, _S2),
    provenance:explain(similar_failure(A2, B, Sim), Proof),
    B \== A2,
    Sim >= 0.45,
    proof_success(Proof),
    render_proof(Proof, Text),
    sub_atom(Text, _, _, _, 'failure_similarity_rule').

test(known_solution_suggested) :-
    with_attempt(test_expert, throw(emacs_daemon_socket_permission_denied), R1),
    R1 = outcome_report(A1, failure, _, _, _),
    record_solution('emacs daemon socket permission denied',
                    'run systemctl --user restart emacs; chmod the socket dir',
                    'dotfiles_expert', _S),
    with_attempt(test_expert, throw(emacs_daemon_socket_permission_denied_again), R2),
    R2 = outcome_report(A2, failure, _, _, Sol2),
    Sol2 \= [],
    member(sol(S, Steps, Src), Sol2),
    atom(Steps),
    Src == dotfiles_expert,
    solution_for_failure(S, A1),
    attempt_expert(A1, test_expert),
    suggested_solution(A2, S, _Sim).

test(failure_warnings_lists_similar_text) :-
    with_attempt(test_expert, throw(plunit_daemon_crash_repeated), _),
    with_attempt(test_expert, throw(plunit_daemon_crash_again), _),
    failure_warnings('plunit_daemon_crash_third', Warnings, _),
    Warnings \= [],
    member(w(_Sim, _A, Txt), Warnings),
    atom(Txt).

test(threshold_configurable) :-
    set_failure_threshold(0.9),
    failure_sim_threshold(0.9),
    set_failure_threshold(0.45),
    failure_sim_threshold(0.45).

:- end_tests(outcomes).
