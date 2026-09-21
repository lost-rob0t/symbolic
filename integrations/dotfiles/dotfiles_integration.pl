:- module(dotfiles_integration, [
              dotfiles_home/1,
              dotfiles_mine/0,
              dotfiles_expert_load/0,
              dotfiles_upstream_init/0,
              dotfiles_upstream_status/1
          ]).

:- use_module(library(lists)).
:- use_module('../../rlm/mining/file_mine').
:- use_module('../../rlm/harness/symbolic_rlm').

dotfiles_home(Home) :-
    (   getenv('DOTFILES_HOME', H)
    ->  Home = H
    ;   expand_file_name('~/.dotfiles', [H0]),
        Home = H0
    ).

dotfiles_mine :-
    dotfiles_home(Home),
    file_mine:mine_repository(Home, dotfiles, [depth(4)]).

dotfiles_expert_load :-
    dotfiles_home(Home),
    format(atom(Expert), '~w/.zara/experts/dotfiles_expert/dotfiles_expert.pl', [Home]),
    (   exists_file(Expert)
    ->  ensure_loaded_once(Expert)
    ;   true
    ).

:- dynamic expert_loaded_i/1.

ensure_loaded_once(Expert) :-
    expert_loaded_i(Expert),
    !.
ensure_loaded_once(Expert) :-
    assertz(expert_loaded_i(Expert)),
    consult(Expert).

dotfiles_upstream_init :-
    dotfiles_mine,
    dotfiles_expert_load.

dotfiles_upstream_status(status{home: Home,
                                mined: Mined,
                                expert: Expert}) :-
    dotfiles_home(Home),
    (   file_mine:mined_repo_i(dotfiles, Home)
    ->  Mined = yes
    ;   Mined = no
    ),
    dotfiles_home(H),
    format(atom(ExpertFile), '~w/.zara/experts/dotfiles_expert/dotfiles_expert.pl', [H]),
    (   exists_file(ExpertFile)
    ->  Expert = available
    ;   Expert = missing
    ).
