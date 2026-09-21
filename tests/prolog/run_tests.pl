:- use_module(library(plunit)).

run_all(Dir) :-
    atomic_list_concat([Dir, '/../../prolog/symbolic.pl'], KB),
    consult(KB),
    atomic_list_concat([Dir, '/core_tests.pl'], T1),
    atomic_list_concat([Dir, '/provenance_tests.pl'], T2),
    atomic_list_concat([Dir, '/learning_tests.pl'], T3),
    atomic_list_concat([Dir, '/aw_ingest_tests.pl'], T4),
    atomic_list_concat([Dir, '/rlm_tests.pl'], T5),
    atomic_list_concat([Dir, '/outcome_tests.pl'], T6),
    consult(T1),
    consult(T2),
    consult(T3),
    consult(T4),
    consult(T5),
    consult(T6),
    run_tests.

:- (   prolog_load_context(source, Src),
       file_directory_name(Src, Dir),
       run_all(Dir)
   ->  true
   ;   print_message(error, run_all_failed)
   ).
