:- module(git_ontology, [
              commit/1,
              branch/1,
              tag/1,
              worktree/2,
              tag_points_at/2,
              branch_head/2,
              commit_parent/2,
              commit_in_repo/2,
              issue_ref/3
          ]).

:- use_module(core).
:- use_module(provenance).
:- use_module(source_code).

:- dynamic worktree_i/3.
:- dynamic tag_points_at_i/2.
:- dynamic branch_head_i/3.
:- dynamic commit_parent_i/2.
:- dynamic commit_in_repo_i/2.
:- dynamic issue_ref_i/4.

commit(C) :-
    commit_in_repo_i(C, _, _).

branch(B) :-
    branch_head_i(B, _, _).

tag(T) :-
    tag_points_at_i(T, _).

worktree(Path, Repo, Branch) :-
    worktree_i(Path, Repo, Branch).

tag_points_at(Tag, Commit) :-
    tag_points_at_i(Tag, Commit).

branch_head(Branch, Commit, Time) :-
    branch_head_i(Branch, Commit, Time).

commit_parent(Commit, Parent) :-
    commit_parent_i(Commit, Parent).

commit_in_repo(Commit, Repo) :-
    commit_in_repo_i(Commit, Repo).

issue_ref(Commit, Tracker, Ref) :-
    issue_ref_i(Commit, Tracker, Ref).
