:- module(kb_tools, [
              kb_query/2,
              kb_explain/2,
              kb_related/2,
              kb_assert_candidate/3,
              kb_search_code/2,
              kb_search_docs/2,
              kb_git_history/2,
              kb_service_state/1,
              kb_process_state/1,
              kb_session_history/2,
              kb_debug_context/2
          ]).

:- use_module(library(lists)).
:- use_module(library(apply)).
:- use_module('../../ontology/core').
:- use_module('../../ontology/provenance').
:- use_module('../../ontology/computing').
:- use_module('../../ontology/source_code').
:- use_module('../../ontology/documentation').
:- use_module('../../ontology/session').
:- use_module('../../ontology/activity').
:- use_module('../../ontology/learning').

:- meta_predicate kb_query(0, -).

kb_query(Goal, Results) :-
    findall(Goal, Goal, Results).

kb_explain(Goal, Text) :-
    explain(Goal, Proof),
    render_proof(Proof, Text).

kb_related(Entity, Related) :-
    findall(R,
            (   documentation:documents(Doc, Entity), R = documented_by(Doc)
            ;   source_code:defines(File, Entity, _), R = defined_in(File)
            ;   source_code:defines(File, Entity, _),
                source_code:file_in_repo(File, Repo, _),
                R = in_repository(Repo)
            ;   session:session_touched_file(S, Entity),
                R = touched_by_session(S)
            ;   activity:project_activity(Entity, _, _), R = has_activity
            ;   documentation:documents(Entity, E2), R = documents_entity(E2)
            ;   source_code:commit_touches(Commit, Entity),
                R = touched_by_commit(Commit)
            ),
            RelatedUnsorted),
    sort(RelatedUnsorted, Related).

kb_assert_candidate(candidate_fact, Term, ProposalId) :-
    create_proposal(candidate_fact,
                    fact_assert(claim, Term, [asserted_by(candidate_agent)]),
                    ProposalId).
kb_assert_candidate(candidate_rule, rule(Id, Head, Body), ProposalId) :-
    create_proposal(candidate_rule, rule(Id, Head, Body), ProposalId).
kb_assert_candidate(Kind, Content, ProposalId) :-
    create_proposal(Kind, Content, ProposalId).

create_proposal(Kind, Content, ProposalId) :-
    core:iso_now(Now),
    format(atom(ProposalId), 'prop_~w', [Now]),
    assertz(learning:proposal_i(ProposalId, Kind, Content)),
    provenance:register_knowledge(ProposalId, proposal,
                                  [asserted_by(candidate_agent),
                                   about(Kind)]).

kb_search_code(Pattern, Matches) :-
    atom(Pattern),
    findall(match(File, Symbol, Kind),
            (   (   source_code:defines(File, Symbol, Kind)
                ;   source_code:references(File, Symbol, Kind)
                ),
                symbol_matches(Symbol, Pattern)
            ),
            MatchesUnsorted),
    sort(MatchesUnsorted, Matches).

symbol_matches(Symbol, Pattern) :-
    term_to_atom(Symbol, A),
    downcase_atom(A, DA),
    downcase_atom(Pattern, DP),
    (   DA == DP
    ;   sub_atom(DA, _, _, _, DP)
    ).

kb_search_docs(Query, Docs) :-
    downcase_atom(Query, DQ),
    findall(doc(D, What),
            (   documentation:doc_section(D, Title, _),
                What = section(Title),
                atom_match(Title, DQ)
            ;   documentation:doc_mentions(D, Term, _),
                What = mention(Term),
                atom_match(Term, DQ)
            ;   documentation:documents_command(D, Cmd),
                What = command(Cmd),
                atom_match(Cmd, DQ)
            ;   documentation:configuration_key(D, Key),
                What = config_key(Key),
                atom_match(Key, DQ)
            ),
            DocsUnsorted),
    sort(DocsUnsorted, Docs).

atom_match(Value, Pattern) :-
    downcase_atom(Value, DV),
    sub_atom(DV, _, _, _, Pattern).

kb_git_history(File, History) :-
    findall(info(Commit, Time, Author),
            (   source_code:last_changed(File, Commit, Time),
                source_code:commit_author(Commit, Author, _)
            ),
            History).

kb_service_state(States) :-
    findall(state(Service, State, Time),
            computing:service_state(Service, State, Time),
            States).

kb_process_state(Procs) :-
    findall(proc(P, Exe, Cmd),
            (   computing:process_exe(P, Exe),
                (   computing:process_cmd(P, Cmd)
                ->  true
                ;   Cmd = unknown
                )
            ),
            Procs).

kb_session_history(Project, Sessions) :-
    findall(sess(S, Dir, Started),
            (   session:session_workdir(S, Dir),
                source_code:project_root_dir(Project, Dir),
                session:session_started(S, Started)
            ),
            Sessions).

kb_debug_context(Subject, Context) :-
    downcase_atom(Subject, DS),
    findall(piece(Kind, Term),
            (   computing:service_state(Subject, State, T),
                Kind = service_state, Term = state(State, T)
            ;   computing:service_unit(Subject, Unit),
                Kind = unit, Term = Unit
            ;   computing:process_cmd(P, Cmd),
                atom(Cmd), atom_match(Cmd, DS),
                Kind = process, Term = proc(P, Cmd)
            ;   computing:package_owns(Pkg, Path),
                atom(Path), atom_match(Path, DS),
                Kind = package, Term = pkg(Pkg, Path)
            ;   session:session_failed_because(S, Cause),
                Kind = prior_session_failure, Term = failed(S, Cause)
            ;   documentation:doc_section(D, Title, _),
                atom_match(Title, DS),
                Kind = doc, Term = doc(D, Title)
            ),
            Pieces),
    Context = debug_context(Subject, Pieces).
