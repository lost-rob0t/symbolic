:- module(expert_registration, [
              registered_experts/1
          ]).

:- use_module(library(lists)).
:- use_module('../../ontology/core').
:- use_module('../tools/kb_tools').
:- use_module('../tools/web_tools').
:- use_module('../harness/symbolic_rlm').

register_all :-
    symbolic_rlm:symbolic_rlm_init,
    symbolic_rlm:current_registry(Registry),
    forall(expert_spec(Contract, Keywords),
           (   expert_register(Registry, Contract, _),
               catch(symbolic_moe:moe_register(Registry, Contract, Keywords),
                     _, true)
           )).

expert_spec(Contract, Keywords) :-
    Contract = expert_contract(kb_query_expert, '0.1.0', kb_query/2, 40,
                               expert_registration:kb_query_handler),
    Keywords = [query, ask, facts, find, all].

expert_spec(Contract, Keywords) :-
    Contract = expert_contract(kb_explain_expert, '0.1.0', kb_explain_goal/2, 40,
                               expert_registration:kb_explain_handler),
    Keywords = [explain, why, proof, provenance, justify].

expert_spec(Contract, Keywords) :-
    Contract = expert_contract(kb_related_expert, '0.1.0', kb_related_goal/2, 35,
                               expert_registration:kb_related_handler),
    Keywords = [related, connected, neighbors, graph].

expert_spec(Contract, Keywords) :-
    Contract = expert_contract(kb_candidate_expert, '0.1.0', kb_candidate/3, 30,
                               expert_registration:kb_candidate_handler),
    Keywords = [candidate, propose, learn, new_fact, new_rule].

expert_spec(Contract, Keywords) :-
    Contract = expert_contract(kb_code_expert, '0.1.0', kb_code/2, 45,
                               expert_registration:kb_code_handler),
    Keywords = [code, symbol, function, defines, where, search_code].

expert_spec(Contract, Keywords) :-
    Contract = expert_contract(kb_docs_expert, '0.1.0', kb_docs/2, 45,
                               expert_registration:kb_docs_handler),
    Keywords = [docs, documentation, readme, manual, config_key].

expert_spec(Contract, Keywords) :-
    Contract = expert_contract(kb_git_expert, '0.1.0', kb_git/2, 40,
                               expert_registration:kb_git_handler),
    Keywords = [git, commit, history, introduced, last_changed].

expert_spec(Contract, Keywords) :-
    Contract = expert_contract(kb_services_expert, '0.1.0', kb_services/1, 40,
                               expert_registration:kb_services_handler),
    Keywords = [services, systemd, units, state].

expert_spec(Contract, Keywords) :-
    Contract = expert_contract(kb_sessions_expert, '0.1.0', kb_sessions/2, 40,
                               expert_registration:kb_sessions_handler),
    Keywords = [sessions, opencode, history, worked_before].

expert_spec(Contract, Keywords) :-
    Contract = expert_contract(kb_debug_ctx_expert, '0.1.0', kb_debug_ctx/2, 38,
                               expert_registration:kb_debug_ctx_handler),
    Keywords = [debug_context, evidence, gather].

expert_spec(Contract, Keywords) :-
    Contract = expert_contract(brave_expert, '0.1.0', brave/2, 20,
                               expert_registration:brave_handler),
    Keywords = [web, search, brave, internet, lookup].

expert_spec(Contract, Keywords) :-
    Contract = expert_contract(web_fetch_expert, '0.1.0', web_fetch_goal/2, 20,
                               expert_registration:web_fetch_handler),
    Keywords = [fetch, url, page, download].

expert_spec(Contract, Keywords) :-
    Contract = expert_contract(wikipedia_expert, '0.1.0', wikipedia/2, 20,
                               expert_registration:wikipedia_handler),
    Keywords = [wikipedia, encyclopedia, article, knowledge_article].

kb_query_handler(kb_query(Goal, _Results), _Ctx, Value) :-
    kb_tools:kb_query(Goal, Results),
    Value = results(Results).

kb_explain_handler(kb_explain_goal(Goal, _Text), _Ctx, Value) :-
    kb_tools:kb_explain(Goal, Text),
    Value = proof(Text).

kb_related_handler(kb_related_goal(Entity, _Related), _Ctx, Value) :-
    kb_tools:kb_related(Entity, Related),
    Value = related(Related).

kb_candidate_handler(kb_candidate(Kind, Content, _Id), _Ctx, Value) :-
    kb_tools:kb_assert_candidate(Kind, Content, Id),
    Value = proposal(Id).

kb_code_handler(kb_code(Pattern, _Matches), _Ctx, Value) :-
    kb_tools:kb_search_code(Pattern, Matches),
    Value = code_matches(Matches).

kb_docs_handler(kb_docs(Query, _Docs), _Ctx, Value) :-
    kb_tools:kb_search_docs(Query, Docs),
    Value = docs(Docs).

kb_git_handler(kb_git(File, _History), _Ctx, Value) :-
    kb_tools:kb_git_history(File, History),
    Value = git_history(History).

kb_services_handler(kb_services(_States), _Ctx, Value) :-
    kb_tools:kb_service_state(States),
    Value = services(States).

kb_sessions_handler(kb_sessions(Project, _Sessions), _Ctx, Value) :-
    kb_tools:kb_session_history(Project, Sessions),
    Value = sessions(Sessions).

kb_debug_ctx_handler(kb_debug_ctx(Subject, _Context), _Ctx, Value) :-
    kb_tools:kb_debug_context(Subject, Context),
    Value = context(Context).

brave_handler(brave(Query, _Text), _Ctx, Value) :-
    web_tools:brave_search(Query, Text),
    Value = web(Text).

web_fetch_handler(web_fetch_goal(URL, _Text), _Ctx, Value) :-
    web_tools:web_fetch(URL, Text),
    Value = page(Text).

wikipedia_handler(wikipedia(Title, _Summary), _Ctx, Value) :-
    web_tools:wikipedia_summary(Title, Summary),
    Value = wiki(Summary).

registered_experts(Experts) :-
    symbolic_rlm:current_registry(Registry),
    expert_catalog(Registry, Experts).

:- register_all.
