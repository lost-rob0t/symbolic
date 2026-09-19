:- module(filesystem, [
              file/1,
              directory/1,
              project_root/2,
              file_path/2,
              file_ext/2,
              file_size/2,
              file_mtime/2,
              file_owner/2,
              config_file/1,
              doc_file/1,
              manifest/1,
              important_path/2
          ]).

:- use_module(core).
:- use_module(provenance).
:- use_module(source_code).

:- dynamic file_path_i/2.
:- dynamic file_meta_i/3.
:- dynamic project_root_i/3.
:- dynamic important_path_i/2.

file(F) :-
    file_path_i(F, _).

directory(D) :-
    core:kind_instance(D, directory).

project_root(Root, Project, Time) :-
    project_root_i(Root, Project, Time).

file_path(F, P) :-
    file_path_i(F, P).

file_ext(F, Ext) :-
    file_path_i(F, P),
    file_name_extension(_, Ext, P),
    Ext \= ''.

file_size(F, S) :-
    file_meta_i(F, size, S).

file_mtime(F, T) :-
    file_meta_i(F, mtime, T).

file_owner(F, U) :-
    file_meta_i(F, owner, U).

config_file(F) :-
    file_path_i(F, P),
    config_path(P).

doc_file(F) :-
    source_code:documented_by(F, _).
doc_file(F) :-
    file_path_i(F, P),
    doc_path(P).

manifest(F) :-
    file_path_i(F, P),
    manifest_path(P).

config_path(P) :-
    atom(P),
    (   sub_atom(P, _, _, _, '/.config/')
    ;   sub_atom(P, _, 6, 0, '/etc/')
    ;   file_name_extension(_, Ext, P),
        config_ext(Ext)
    ).

config_ext('conf').
config_ext('cfg').
config_ext('toml').
config_ext('yaml').
config_ext('yml').
config_ext('ini').

doc_path(P) :-
    file_name_extension(_, Ext, P),
    doc_ext(Ext).

doc_ext('md').
doc_ext('org').
doc_ext('rst').
doc_ext('txt').

manifest_path(P) :-
    file_name_extension(Base, Ext, P),
    manifest_base(Base, Ext).

manifest_base('Makefile', '').
manifest_base('flake.nix', 'nix').
manifest_base('package.json', 'json').
manifest_base('Cargo.toml', 'toml').
manifest_base('setup.py', 'py').

important_path(P, Kind) :-
    important_path_i(P, Kind).
