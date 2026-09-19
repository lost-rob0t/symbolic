:- module(provenance_tests, []).
:- use_module(library(plunit)).
:- use_module('../../ontology/core').
:- use_module('../../ontology/provenance').

:- begin_tests(provenance).

test(register_observation) :-
    register_knowledge(obs_1, observation, [asserted_by(aw_collector), about(flake)]),
    observation(obs_1),
    epistemic_status(obs_1, observation),
    asserted_by(obs_1, aw_collector),
    asserted_at(obs_1, _),
    observation_of(obs_1, flake).

test(no_duplicate_knowledge_ids) :-
    register_knowledge(obs_2, observation, []),
    \+ register_knowledge(obs_2, claim, []).

test(no_invalid_status) :-
    \+ register_knowledge(obs_3, vibration, []).

test(observation_metadata_edges) :-
    assertz(provenance:observed_by_i(obs_4, systemd_collector)),
    assertz(provenance:observed_at_i(obs_4, '2026-09-19T12:00:00Z')),
    assertz(provenance:observation_source_i(obs_4, source(journalctl, 'unit=dunst'))),
    observed_by(obs_4, systemd_collector),
    observed_at(obs_4, '2026-09-19T12:00:00Z'),
    observation_source(obs_4, source(journalctl, 'unit=dunst')).

test(claim_extracted_from_observation) :-
    register_knowledge(claim_1, claim, [asserted_by(extractor_llm), generator('glm-5.3-flash', '2026-09'), confidence(0.72)]),
    assertz(provenance:extracted_from_i(claim_1, obs_1)),
    assertz(provenance:claim_content_i(claim_1, uses(dunst, notify_send))),
    extracted_from(claim_1, obs_1),
    extracted_by(claim_1, extractor_llm),
    claim_content(claim_1, uses(dunst, notify_send)),
    confidence(claim_1, 0.72),
    generator(claim_1, 'glm-5.3-flash', '2026-09').

test(rule_declare_and_explain) :-
    test_dir(Dir),
    atomic_list_concat([Dir, '/../../prolog/rules/activity_rules.pl'], RulesFile),
    consult(RulesFile),
    assertz(activity:application_session_i(emacs, '2026-09-19T10:00:00Z', '2026-09-19T11:00:00Z')),
    explain(time_spent(emacs, Interval, Duration), Proof),
    Interval == interval('2026-09-19T10:00:00Z', '2026-09-19T11:00:00Z'),
    Duration =:= 3600,
    proof_success(Proof),
    render_proof(Proof, Text),
    sub_atom(Text, _, _, _, 'time_spent_rule').

:- prolog_load_context(source, Src0),
   file_directory_name(Src0, Dir0),
   assertz(test_dir(Dir0)).

test(shadow_rules_excluded_from_explanation, [cleanup(cleanup_shadow_fixtures)]) :-
    assertz(shadow_fixture_pred(y)),
    assertz(provenance:kb_rule_i(shadow_fixture_rule, provenance,
                                 shadow_fixture_pred(x), true)),
    assertz(provenance:rule_status_i(shadow_fixture_rule, shadow)),
    \+ explain(shadow_fixture_pred(x), _),
    explain(shadow_fixture_pred(y), _).

cleanup_shadow_fixtures :-
    retractall(shadow_fixture_pred(_)),
    retractall(provenance:kb_rule_i(shadow_fixture_rule, _, _, _)),
    retractall(provenance:rule_status_i(shadow_fixture_rule, _)).

test(evidence_chain_walks_provenance) :-
    register_knowledge(f_1, fact, [asserted_by(test)]),
    assertz(provenance:supported_by_i(f_1, claim_1)),
    evidence_chain(f_1, chain(f_1, Children)),
    member(chain(claim_1, _), Children).

test(supersedes) :-
    assertz(provenance:supersedes_i(fact_new_1, fact_old_1)),
    supersedes(fact_new_1, fact_old_1).

:- end_tests(provenance).
