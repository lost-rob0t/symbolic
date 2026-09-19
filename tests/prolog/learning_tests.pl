:- module(learning_tests, []).
:- use_module(library(plunit)).
:- use_module('../../ontology/core').
:- use_module('../../ontology/provenance').
:- use_module('../../ontology/learning').

:- begin_tests(governance).

test(council_has_five_roles) :-
    findall(R, council_role(R), Roles),
    length(Roles, 5).

test(additive_needs_four_of_five) :-
    approval_threshold(additive, 4).

test(breaking_needs_unanimous) :-
    approval_threshold(breaking, 5).

test(proposal_lifecycle_open, [true(ProposalState == open)]) :-
    assertz(learning:proposal_i(prop_1, candidate_fact, fact_assert(fact, some_fact(x), []))),
    proposal_state(prop_1, ProposalState),
    approval_count(prop_1, 0),
    \+ quorum_met(prop_1),
    !.

test(additive_promotion_at_threshold) :-
    assertz(learning:proposal_i(prop_2, candidate_fact, fact_assert(fact, promoted_fact(a), [asserted_by(test)]))),
    forall(council_role(Role), assertz(learning:vote_i(prop_2, Role, approve, r))),
    once(quorum_met(prop_2)),
    once(promotable(prop_2)),
    promote(prop_2),
    proposal_state(prop_2, promoted),
    provenance:fact(promoted_fact(a)),
    provenance:asserted_by(promoted_fact(a), test).

test(additive_blocked_below_threshold) :-
    assertz(learning:proposal_i(prop_3, candidate_fact, fact_assert(fact, blocked_fact(a), []))),
    assertz(learning:vote_i(prop_3, ontologist, approve, r)),
    assertz(learning:vote_i(prop_3, evidence_miner, approve, r)),
    assertz(learning:vote_i(prop_3, rule_engineer, approve, r)),
    \+ quorum_met(prop_3).

test(single_reject_blocks_additive) :-
    assertz(learning:proposal_i(prop_4, candidate_fact, fact_assert(fact, x(a), []))),
    forall(council_role(Role), assertz(learning:vote_i(prop_4, Role, approve, r))),
    retract(learning:vote_i(prop_4, drift_auditor, approve, r)),
    assertz(learning:vote_i(prop_4, drift_auditor, reject, unclear_evidence)),
    approval_count(prop_4, 4),
    \+ quorum_met(prop_4).

test(breaking_requires_all_five) :-
    assertz(learning:proposal_i(prop_5, ontology_change, none)),
    forall(council_role(Role), assertz(learning:vote_i(prop_5, Role, approve, r))),
    quorum_met(prop_5),
    retract(learning:vote_i(prop_5, adversarial_critic, approve, r)),
    assertz(learning:vote_i(prop_5, adversarial_critic, reject, risky)),
    \+ quorum_met(prop_5).

test(candidate_rule_requires_shadow_pass) :-
    assertz(learning:proposal_i(prop_6, candidate_rule,
                                rule(shadow_candidate_1, doubled(Y, Z), (number(Y), Z is 2 * Y)))),
    forall(council_role(Role), assertz(learning:vote_i(prop_6, Role, approve, r))),
    \+ promotable(prop_6),
    shadow_fail(prop_6, shadow_candidate_1),
    \+ promotable(prop_6),
    retractall(learning:shadow_result_i(prop_6, shadow_candidate_1, _)),
    shadow_pass(prop_6, shadow_candidate_1),
    once(promotable(prop_6)),
    promote(prop_6),
    proposal_state(prop_6, promoted),
    provenance:explain(doubled(3, Z), _),
    Z == 6.

test(shadow_fail_blocks_promotion_even_with_quorum) :-
    assertz(learning:proposal_i(prop_7, candidate_rule, rule(bad_rule_1, never_true(a), fail))),
    forall(council_role(Role), assertz(learning:vote_i(prop_7, Role, approve, r))),
    shadow_fail(prop_7, bad_rule_1),
    \+ promotable(prop_7).

test(rejection_recorded) :-
    assertz(learning:proposal_i(prop_8, candidate_fact, none)),
    record_rejection(prop_8, policy_violation),
    proposal_state(prop_8, rejected),
    learning:rejection_i(prop_8, policy_violation, _).

:- end_tests(governance).
