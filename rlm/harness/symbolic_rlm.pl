:- module(symbolic_rlm, [
              symbolic_rlm_init/0,
              symbolic_rlm_status/1,
              current_registry/1,
              with_registry/1,
              expert_registry_create/1,
              expert_registry_destroy/1,
              expert_register/3,
              expert_catalog/2,
              expert_select/4,
              expert_invoke/5,
              expert_call/4
          ]).

:- use_module(library(lists)).

:- dynamic current_registry_i/1.
:- dynamic backend/1.
:- dynamic this_file/1.

:- prolog_load_context(source, ThisSrc),
   assertz(this_file(ThisSrc)).

symbolic_rlm_init :-
    (   current_registry_i(_)
    ->  true
    ;   ensure_backend,
        Registry = expert_registry(symbolic_main),
        registry_call(expert_registry_create(Registry)),
        assertz(current_registry_i(Registry))
    ).

ensure_backend :-
    backend(_),
    !.
ensure_backend :-
    (   getenv('SYMBOLIC_PROLOG_RLM', EnvHome)
    ->  atomic_list_concat([EnvHome, '/prolog/rlm_expert.pl'], Upstream),
        (   exists_file(Upstream)
        ->  use_module(Upstream, []),
            assertz(backend(upstream(EnvHome)))
        ;   load_compat
        )
    ;   load_compat
    ).

load_compat :-
    this_file(ThisFile),
    file_directory_name(ThisFile, Dir),
    atomic_list_concat([Dir, '/expert_registry_compat.pl'], Compat),
    use_module(Compat, []),
    assertz(backend(compat)).

registry_call(Goal) :-
    (   backend(compat)
    ->  expert_registry_compat:Goal
    ;   backend(upstream(_))
    ->  rlm_expert:Goal
    ;   throw(error(registry_backend_uninitialized, _))
    ).

expert_registry_create(Registry) :-
    registry_call(expert_registry_create(Registry)).

expert_registry_destroy(Registry) :-
    registry_call(expert_registry_destroy(Registry)).

expert_register(Registry, Contract, Outcome) :-
    registry_call(expert_register(Registry, Contract, Outcome)).

expert_catalog(Registry, Experts) :-
    registry_call(expert_catalog(Registry, Experts)).

expert_select(Registry, Goal, Context, Outcome) :-
    registry_call(expert_select(Registry, Goal, Context, Outcome)).

expert_invoke(Registry, Goal, Context, Timeout, Outcome) :-
    registry_call(expert_invoke(Registry, Goal, Context, Timeout, Outcome)).

expert_call(Registry, Goal, Context, Outcome) :-
    registry_call(expert_call(Registry, Goal, Context, Outcome)).

current_registry(Registry) :-
    symbolic_rlm_init,
    current_registry_i(Registry).

with_registry(Goal) :-
    current_registry(Registry),
    call(Goal, Registry).

symbolic_rlm_status(status{backend: B, registry: R}) :-
    (   backend(B)
    ->  true
    ;   B = uninitialized
    ),
    (   current_registry_i(R)
    ->  true
    ;   R = none
    ).
