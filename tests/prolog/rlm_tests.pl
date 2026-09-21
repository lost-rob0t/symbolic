:- module(rlm_tests, []).
:- use_module(library(plunit)).
:- use_module('../../ontology/core').
:- use_module('../../ontology/provenance').
:- use_module('../../ontology/computing').
:- use_module('../../ontology/learning').
:- use_module('../../rlm/harness/symbolic_rlm').
:- use_module('../../rlm/experts/symbolic_moe').
:- use_module('../../rlm/experts/software_debugger').
:- use_module('../../rlm/experts/expert_registration').
:- use_module('../../rlm/tools/kb_tools').
:- use_module('../../rlm/mining/file_mine').

:- begin_tests(rlm_harness).

test(registry_and_registration) :-
    symbolic_rlm_init,
    current_registry(Registry),
    expert_catalog(Registry, Experts),
    member(E, Experts),
    contract_id(E, software_debugger),
    registered_experts(All),
    length(All, N),
    N >= 13.

test(expert_select_orders_by_priority) :-
    current_registry(Registry),
    expert_select(Registry, kb_docs(foo, _Docs), none, ok([Best|_])),
    contract_id(Best, kb_docs_expert).

test(moe_route_picks_debugger) :-
    assertz(computing:service_state_i(mysvc, failed, '2026-09-19T10:00:00Z')),
    current_registry(Registry),
    moe_route(Registry, debug(mysvc), Outcome),
    Outcome = ok(Report, Contract, _Score),
    contract_id(Contract, software_debugger),
    Report = debug_report(_, Candidates, _),
    Candidates \= [],
    member(cause(Cause, _Ev, _Proof), Candidates),
    Cause = broken_service(failed, '2026-09-19T10:00:00Z').

test(moe_route_falls_through_failing_handler) :-
    current_registry(Registry),
    Failing = expert_contract(failing_expert, '0.1.0', probe/1, 90,
                              rlm_tests:always_fail),
    Passing = expert_contract(passing_expert, '0.1.0', probe/1, 10,
                              rlm_tests:always_ok),
    expert_register(Registry, Failing, _),
    expert_register(Registry, Passing, _),
    moe_route(Registry, probe(x), Outcome),
    Outcome = ok(Value, Contract, _),
    contract_id(Contract, passing_expert),
    Value == fine.

test(moe_selection_recorded_with_provenance) :-
    moe_selections(Sels),
    Sels \= [],
    member(sel(_T, Goal, _Expert, selection(_S, _A)), Sels),
    provenance:inference(_),
    true.

test(candidate_pipeline_through_council) :-
    kb_tools:kb_assert_candidate(candidate_fact, loves_kb(flake, emacs), P),
    provenance:epistemic_status(P, proposal),
    forall(learning:council_role(Role),
           assertz(learning:vote_i(P, Role, approve, ok))),
    once(learning:promotable(P)),
    learning:promote(P),
    learning:proposal_state(P, promoted),
    provenance:claim(loves_kb(flake, emacs)),
    provenance:asserted_by(loves_kb(flake, emacs), candidate_agent).

test(kb_explain_renders_proof) :-
    kb_tools:kb_explain(candidate_cause(mysvc, Cause, _Ev), Text),
    sub_atom(Text, _, _, _, 'candidate_cause_service_rule'),
    Cause = broken_service(failed, _).

test(kb_related_finds_defines) :-
    assertz(documentation:documents_i(aw_docs, mysvc)),
    kb_tools:kb_related(mysvc, Related),
    member(documented_by(aw_docs), Related).

:- end_tests(rlm_harness).

always_fail(_, _, error(deliberate)).
always_ok(_, _, fine).

:- begin_tests(file_mining).

fixture_dir(Dir) :-
    tmp_name(Tmp),
    format(atom(Dir), '/tmp/opencode/~w', [Tmp]).

setup_repo(Dir) :-
    make_directory(Dir),
    atom_concat(Dir, '/sample.py', PyF),
    atom_concat(Dir, '/sample.pl', PlF),
    atom_concat(Dir, '/README.org', OrgF),
    open(PyF, write, S1),
    write(S1, "import os\nclass Miner:\n    def run(self):\n        pass\n"),
    close(S1),
    open(PlF, write, S2),
    write(S2, ":- module(sample, []).\n:- use_module(library(lists)).\n"),
    close(S2),
    open(OrgF, write, S3),
    write(S3, "* Sample Heading\nsome text\n"),
    close(S3).

teardown_repo(Dir) :-
    forall(file_entries(Dir, F), delete_file(F)),
    delete_directory(Dir).

file_entries(Dir, F) :-
    directory_files(Dir, Es),
    member(E, Es),
    E \= '.', E \= '..',
    atom_concat(Dir, '/', P),
    atom_concat(P, E, F).

test(mine_and_incremental, [setup((fixture_dir(Dir), setup_repo(Dir))), cleanup(teardown_repo(Dir))]) :-
    mine_repository(Dir, test_repo),
    atom_concat(Dir, '/sample.py', PyF),
    atom_concat(Dir, '/sample.pl', PlF),
    source_code:language(PyF, python),
    source_code:defines(PyF, Miner, class),
    source_code:defines(PyF, run, function),
    source_code:defines(PlF, sample, module),
    source_code:imports(PlF, 'library(lists)'),
    source_code:file_in_repo(PyF, test_repo, 'sample.py'),
    documentation:doc_format(_OrgF0, org),
    findall(F, file_mine:source_hash_i(F, _, test_repo), Hashes1),
    length(Hashes1, 3),
    mine_repository(Dir, test_repo),
    findall(F, file_mine:source_hash_i(F, _, test_repo), Hashes2),
    sort(Hashes2, S2),
    sort(Hashes1, S1),
    S2 == S1.

test(change_detected_on_edit, [setup((fixture_dir(Dir), setup_repo(Dir))), cleanup(teardown_repo(Dir))]) :-
    mine_repository(Dir, change_repo),
    atom_concat(Dir, '/sample.py', PyF),
    open(PyF, append, S),
    write(S, "\ndef added_later():\n    pass\n"),
    close(S),
    mine_repository(Dir, change_repo),
    source_code:defines(PyF, added_later, function).

:- end_tests(file_mining).

tmp_name(T) :-
    get_time(TS),
    format(atom(T), 'symtest_~w', [TS]).
