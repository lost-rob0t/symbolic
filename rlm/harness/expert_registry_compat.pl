:- module(expert_registry_compat, [
              expert_registry_create/1,
              expert_registry_destroy/1,
              expert_register/3,
              expert_catalog/2,
              expert_select/4,
              expert_invoke/5,
              expert_call/4,
              contract_id/2,
              contract_goal/2,
              contract_priority/2,
              contract_handler/2,
              compat_registry_ready/0
          ]).

:- use_module(library(lists)).
:- use_module(library(pairs)).
:- use_module(library(time)).

:- dynamic registry_alive/1.
:- dynamic registry_entry/3.

compat_registry_ready.

expert_registry_create(expert_registry(Id)) :-
    (   var(Id)
    ->  get_time(T),
        format(atom(Id), 'sym_registry_~w', [T])
    ;   true
    ),
    with_mutex(expert_registry_compat,
               assertz(registry_alive(Id))).

expert_registry_destroy(expert_registry(Id)) :-
    with_mutex(expert_registry_compat,
               ( retractall(registry_entry(Id, _, _)),
                 retractall(registry_alive(Id)) )).

expert_register(Registry, Contract, Outcome) :-
    catch(register_checked(Registry, Contract, Outcome),
          expert_fault(Kind, Detail),
          Outcome = error(expert_error(Kind, Detail))).

register_checked(Registry, Contract, Outcome) :-
    registry_id(Registry, RegistryId),
    contract_checked(Contract),
    contract_id(Contract, ExpertId),
    with_mutex(expert_registry_compat,
               (   registry_entry(RegistryId, ExpertId, _)
               ->  Outcome = error(expert_error(duplicate_expert, ExpertId))
               ;   assertz(registry_entry(RegistryId, ExpertId, Contract)),
                   Outcome = ok(ExpertId)
               )).

registry_id(expert_registry(Id), Id).
registry_id(Id, Id) :-
    atom(Id).

contract_checked(Contract) :-
    (   Contract = expert_contract(Id, Version, Op/Arity, Priority, Handler),
        atom(Id),
        ground(Version),
        atom(Op),
        integer(Arity),
        Arity >= 0,
        integer(Priority),
        Handler = Module:Callable,
        atom(Module),
        callable(Callable)
    ->  true
    ;   throw(expert_fault(invalid_contract, invalid))
    ).

contract_id(expert_contract(Id, _, _, _, _), Id).
contract_goal(expert_contract(_, _, Goal, _, _), Goal).
contract_priority(expert_contract(_, _, _, Priority, _), Priority).
contract_handler(expert_contract(_, _, _, _, Handler), Handler).

expert_catalog(Registry, Experts) :-
    registry_id(Registry, RegistryId),
    findall(Contract,
            registry_entry(RegistryId, _, Contract),
            Experts).

expert_select(Registry, Goal, _Context, Outcome) :-
    registry_id(Registry, RegistryId),
    functor(Goal, Op, Arity),
    findall(Prio-Contract,
            (   registry_entry(RegistryId, _, Contract),
                contract_goal(Contract, GoalOp/GoalArity),
                GoalOp == Op,
                GoalArity =:= Arity
            ),
            Pairs0),
    sort(Pairs0, PairsSorted),
    reverse(PairsSorted, Pairs),
    (   Pairs == []
    ->  Outcome = error(expert_error(no_expert, Op/Arity))
    ;   pairs_values(Pairs, Selected),
        Outcome = ok(Selected)
    ).

expert_invoke(Registry, Goal, Context, Timeout, Outcome) :-
    expert_select(Registry, Goal, Context, SelectOutcome),
    (   SelectOutcome = ok([Best|_])
    ->  call_handler(Best, Goal, Context, Value, Timeout, Outcome)
    ;   SelectOutcome = ok([])
    ->  Outcome = error(expert_error(no_expert, none))
    ;   Outcome = SelectOutcome
    ).

call_handler(Contract, Goal, Context, Value, Timeout, Outcome) :-
    contract_handler(Contract, Handler),
    catch(call_with_time_limit(Timeout,
                               call(Handler, Goal, Context, HandlerValue)),
          time_limit_exceeded,
          Fail = timeout),
    (   var(Fail)
    ->  Outcome = ok(HandlerValue)
    ;   Outcome = error(expert_error(timeout, timeout))
    ),
    !.
call_handler(Contract, _Goal, _Context, _Value, _Timeout,
             error(expert_error(handler_failed, Contract))).

expert_call(Registry, Goal, Context, Outcome) :-
    expert_invoke(Registry, Goal, Context, 10, Outcome).
