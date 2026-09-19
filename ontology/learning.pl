:- module(learning, [
              council_role/1,
              approval_threshold/2,
              proposal/1,
              proposal_kind/2,
              proposal_content/2,
              proposal_state/2,
              vote/4,
              approval_count/2,
              reject_count/2,
              quorum_met/1,
              promotable/1,
              promote/1,
              shadow_rule/2,
              shadow_pass/2,
              shadow_fail/2,
              change_class/2,
              record_rejection/2
          ]).

:- use_module(core).
:- use_module(provenance).

:- dynamic proposal_i/3.
:- dynamic proposal_state_i/2.
:- dynamic vote_i/4.
:- dynamic shadow_result_i/3.
:- dynamic rejection_i/3.

council_role(ontologist).
council_role(evidence_miner).
council_role(rule_engineer).
council_role(adversarial_critic).
council_role(drift_auditor).

approval_threshold(additive, 4).
approval_threshold(breaking, 5).

proposal(P) :-
    proposal_i(P, _, _).

proposal_kind(P, K) :-
    proposal_i(P, K, _).

proposal_content(P, C) :-
    proposal_i(P, _, C).

proposal_state(P, open) :-
    proposal_i(P, _, _),
    \+ proposal_state_i(P, _).
proposal_state(P, S) :-
    proposal_state_i(P, S).

vote(P, Role, Vote, Rationale) :-
    vote_i(P, Role, Vote, Rationale).

approval_count(P, N) :-
    proposal(P),
    aggregate_all(count, vote_i(P, _, approve, _), N).

reject_count(P, N) :-
    proposal(P),
    aggregate_all(count, vote_i(P, _, reject, _), N).

quorum_met(P) :-
    proposal_kind(P, K),
    change_class(K, Class),
    approval_threshold(Class, Needed),
    approval_count(P, ApprovalCount),
    ApprovalCount >= Needed,
    \+ (council_role(Role),
        vote_i(P, Role, reject, _)).

promotable(P) :-
    quorum_met(P),
    (   \+ shadow_required(P)
    ;   shadow_passed(P)
    ).

shadow_required(P) :-
    proposal_kind(P, candidate_rule).

shadow_passed(P) :-
    proposal_content(P, rule(Id, _, _)),
    shadow_result_i(P, Id, pass),
    \+ shadow_result_i(P, Id, fail).

shadow_rule(P, RuleId) :-
    proposal_content(P, rule(RuleId, _, _)).

shadow_pass(P, RuleId) :-
    assertz(shadow_result_i(P, RuleId, pass)).

shadow_fail(P, RuleId) :-
    assertz(shadow_result_i(P, RuleId, fail)).

change_class(candidate_fact, additive).
change_class(candidate_alias, additive).
change_class(candidate_relation, additive).
change_class(candidate_rule, additive).
change_class(candidate_concept, additive).
change_class(ontology_change, breaking).
change_class(schema_change, breaking).

promote(P) :-
    promotable(P),
    proposal_content(P, Content),
    apply_content(Content),
    assertz(proposal_state_i(P, promoted)).

record_rejection(P, Reason) :-
    core:iso_now(Now),
    assertz(rejection_i(P, Reason, Now)),
    retractall(proposal_state_i(P, _)),
    assertz(proposal_state_i(P, rejected)).

apply_content(fact_assert(Status, Term, Options)) :-
    provenance:register_knowledge(Term, Status, Options).
apply_content(alias_assert(Entity, Alias)) :-
    core:declare_entity(Entity, _),
    assertz(core:alias_i(Entity, Alias)).
apply_content(rule(Id, Head, Body)) :-
    provenance:declare_rule(Id, Head, Body).
apply_content(rule_retract(Id)) :-
    provenance:retract_rule(Id).
