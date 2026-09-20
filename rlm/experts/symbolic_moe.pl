:- module(symbolic_moe, [
              moe_register/3,
              moe_route/3,
              moe_council/5,
              moe_rank/3,
              moe_selections/1
          ]).

:- use_module(library(lists)).
:- use_module(library(pairs)).
:- use_module('../../ontology/core').
:- use_module('../../ontology/provenance').
:- use_module('../harness/symbolic_rlm').

:- dynamic expert_keywords_i/2.
:- dynamic moe_selection_i/4.

moe_register(Registry, Contract, Keywords) :-
    expert_register(Registry, Contract, _),
    assertz(expert_keywords_i(Contract.id, Keywords)).

moe_route(Registry, Goal, Outcome) :-
    ground(Goal),
    moe_rank(Registry, Goal, Ranked),
    (   Ranked == []
    ->  Outcome = error(expert_error{kind:no_expert, detail:Goal})
    ;   try_chain(Ranked, Goal, Outcome0, Attempted),
        (   Outcome0 = ok(Value, Contract, Score)
        ->  record_selection(Goal, Contract, Score, Attempted),
            Outcome = Outcome0
        ;   Outcome = Outcome0
        )
    ).

try_chain([], _Goal, error(expert_error{kind:all_experts_failed, detail:none}), []).
try_chain([best(Contract, Score)|Rest], Goal, Outcome, [at(Contract.id, Status)|Tail]) :-
    (   run_handler(Contract, Goal, Value, ok)
    ->  Status = ok,
        Outcome = ok(Value, Contract, Score),
        Tail = []
    ;   Status = failed,
        try_chain(Rest, Goal, Outcome, Tail)
    ).

run_handler(Contract, Goal, Value, ok) :-
    Handler = Contract.handler,
    catch(call(Handler, Goal, moe, Value), _, fail),
    \+ Value = error(_).

moe_rank(Registry, Goal, Ranked) :-
    expert_catalog(Registry, Contracts),
    goal_tokens(Goal, GoalAtom),
    findall(Score-best(Contract, Score),
            (   member(Contract, Contracts),
                score_expert(Contract, GoalAtom, Score)
            ),
            Scored),
    keysort(Scored, Sorted),
    reverse(Sorted, Pairs),
    pairs_values(Pairs, Ranked).

score_expert(Contract, GoalAtom, Score) :-
    get_dict(priority, Contract, Priority),
    (   expert_keywords_i(Contract.id, Keywords)
    ->  true
    ;   Keywords = []
    ),
    keyword_hits(Keywords, GoalAtom, 0, Hits),
    Score is Priority + 2 * Hits.

keyword_hits([], _GoalAtom, N, N).
keyword_hits([K|Ks], GoalAtom, Acc, N) :-
    (   sub_atom(GoalAtom, _, _, _, K)
    ->  Acc1 is Acc + 1
    ;   Acc1 = Acc
    ),
    keyword_hits(Ks, GoalAtom, Acc1, N).

goal_tokens(Goal, GoalAtom) :-
    term_to_atom(Goal, A0),
    downcase_atom(A0, GoalAtom).

moe_council(Registry, Goal, K, Values, Trace) :-
    moe_rank(Registry, Goal, Ranked),
    (   length(Ranked, N), N =< K
    ->  Top = Ranked
    ;   length(Top, K),
        append(Top, _, Ranked)
    ),
    findall(Value-Contract,
            (   member(best(Contract, _Score), Top),
                Handler = Contract.handler,
                catch(call(Handler, Goal, council, Value), _, fail),
                \+ Value = error(_)
            ),
            Pairs),
    Pairs \= [],
    Trace = council{asked: Top, answers: Pairs},
    pairs_values(Pairs, Values).

record_selection(Goal, Contract, Score, Attempted) :-
    core:iso_now(Now),
    assertz(moe_selection_i(Now, Goal, Contract.id,
                            selection{score:Score, attempted:Attempted})),
    format(atom(Kid), 'moe_sel_~w_~w', [Now, Contract.id]),
    provenance:register_knowledge(Kid, inference,
                                  [asserted_by(symbolic_moe_router)]).

moe_selections(Selections) :-
    findall(sel(Time, Goal, Expert, S),
            moe_selection_i(Time, Goal, Expert, S),
            Selections).
