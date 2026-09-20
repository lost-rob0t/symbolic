:- use_module(library(lists)).
:- use_module(library(apply)).

symbolic_load_all(Root) :-
    format(atom(OntGlob), '~w/ontology/*.pl', [Root]),
    expand_file_name(OntGlob, OntFiles),
    forall(member(F, OntFiles), use_module(F)),
    format(atom(RulesGlob), '~w/prolog/rules/*.pl', [Root]),
    expand_file_name(RulesGlob, RuleFiles),
    forall(member(F, RuleFiles), ensure_loaded(F)),
    format(atom(ExpGlob), '~w/prolog/experts/*.pl', [Root]),
    expand_file_name(ExpGlob, ExpFiles),
    forall(member(F, ExpFiles), ensure_loaded(F)),
    format(atom(GovGlob), '~w/prolog/governance/*.pl', [Root]),
    expand_file_name(GovGlob, GovFiles),
    forall(member(F, GovFiles), ensure_loaded(F)),
    format(atom(FactsGlob), '~w/prolog/facts/*.pl', [Root]),
    expand_file_name(FactsGlob, FactFiles),
    forall(member(F, FactFiles), ensure_loaded(F)),
    format(atom(GenGlob), '~w/prolog/generated/*.pl', [Root]),
    expand_file_name(GenGlob, GenFiles),
    forall(member(F, GenFiles), ensure_loaded(F)),
    format(atom(HarnFile), '~w/rlm/harness/symbolic_rlm.pl', [Root]),
    ensure_loaded(HarnFile),
    format(atom(MineGlob), '~w/rlm/mining/*.pl', [Root]),
    expand_file_name(MineGlob, MineFiles),
    forall(member(F, MineFiles), ensure_loaded(F)),
    format(atom(ToolGlob), '~w/rlm/tools/*.pl', [Root]),
    expand_file_name(ToolGlob, ToolFiles),
    forall(member(F, ToolFiles), ensure_loaded(F)),
    format(atom(MoeFile), '~w/rlm/experts/symbolic_moe.pl', [Root]),
    ensure_loaded(MoeFile),
    format(atom(ExpGlob2), '~w/rlm/experts/*.pl', [Root]),
    expand_file_name(ExpGlob2, ExpFiles2),
    forall((member(F, ExpFiles2),
            \+ sub_atom(F, _, _, _, 'symbolic_moe')),
           ensure_loaded(F)).

ensure_loaded(File) :-
    loaded_rlm_file(File),
    !.
ensure_loaded(File) :-
    exists_file(File),
    assertz(loaded_rlm_file(File)),
    consult(File).

:- dynamic loaded_rlm_file/1.

registry(provenance:knowledge_i/2).
registry(provenance:asserted_at_i/2).
registry(provenance:asserted_by_i/2).
registry(provenance:generator_i/3).
registry(provenance:observation_of_i/2).
registry(provenance:observed_by_i/2).
registry(provenance:observed_at_i/2).
registry(provenance:observation_source_i/2).
registry(provenance:observation_payload_i/2).
registry(provenance:extracted_from_i/2).
registry(provenance:extracted_by_i/2).
registry(provenance:claim_content_i/2).
registry(provenance:supported_by_i/2).
registry(provenance:confidence_i/2).
registry(provenance:inferred_by_i/2).
registry(provenance:depends_on_i/2).
registry(provenance:supersedes_i/2).
registry(core:entity_i/2).
registry(core:label_i/2).
registry(core:alias_i/2).
registry(computing:service_state_i/3).
registry(computing:process_exe_i/2).
registry(computing:process_cmd_i/2).
registry(computing:process_listens_i/2).
registry(computing:package_version_i/3).
registry(computing:package_owns_i/2).
registry(network:interface_addr_i/3).
registry(network:listening_socket_i/2).
registry(network:socket_port_i/2).
registry(network:socket_proto_i/2).
registry(desktop:window_app_i/2).
registry(desktop:active_window_i/3).
registry(activity:usage_session_i/5).
registry(activity:application_session_i/4).
registry(activity:afk_interval_i/3).
registry(activity:project_activity_i/4).
registry(session:session_i/2).
registry(session:session_workdir_i/2).
registry(source_code:defines_i/4).
registry(source_code:language_i/2).
registry(source_code:file_in_repo_i/3).
registry(documentation:documents_i/2).
registry(learning:proposal_i/3).
registry(learning:proposal_state_i/2).
registry(learning:vote_i/4).
registry(learning:shadow_result_i/3).
registry(learning:rejection_i/3).
registry(file_mine:source_hash_i/3).
registry(file_mine:mined_repo_i/2).
registry(symbolic_moe:expert_keywords_i/2).
registry(symbolic_moe:moe_selection_i/4).
registry(expert_registry_compat:registry_entry/3).
registry(expert_registry_compat:registry_alive/1).
registry(source_code:imports_i/2).
registry(source_code:repo_head_i/3).
registry(documentation:doc_section_i/3).
registry(documentation:doc_format_i/2).
registry(notification:notification_i/2).

kb_reset :-
    forall(registry(M:Name/Arity),
           (   current_predicate(M:Name/Arity),
               functor(Term, Name, Arity),
               retractall(M:Term)
           )).

kb_status(status{knowledge_items: KI, observations: OB, claims: CL, facts: FA, inferences: IN, rules: RL}) :-
    aggregate_all(count, provenance:knowledge_item(_), KI),
    aggregate_all(count, provenance:observation(_), OB),
    aggregate_all(count, provenance:claim(_), CL),
    aggregate_all(count, provenance:fact(_), FA),
    aggregate_all(count, provenance:inference(_), IN),
    aggregate_all(count, (provenance:kb_rule(Id, _, _),
                          \+ provenance:rejected_rule(Id)), RL).

:- (   prolog_load_context(source, Src),
       file_directory_name(Src, PrologDir),
       file_directory_name(PrologDir, Root),
       symbolic_load_all(Root)
   ->  true
   ;   format(user_error, 'symbolic: knowledge base load failed~n', [])
   ).
