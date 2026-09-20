:- module(file_mine, [
              mine_repository/2,
              mine_repository/3,
              miner_status/1
          ]).

:- use_module(library(lists)).
:- use_module(library(apply)).
:- use_module(library(sha)).
:- use_module(library(process)).
:- use_module('../../ontology/core').
:- use_module('../../ontology/provenance').
:- use_module('../../ontology/source_code').
:- use_module('../../ontology/documentation').

:- dynamic source_hash_i/3.
:- dynamic mined_repo_i/2.

miner_status(status{repos_mined: N, files_indexed: F}) :-
    aggregate_all(count, mined_repo_i(_, _), N),
    aggregate_all(count, source_hash_i(_, _, _), F).

mine_repository(Root, RepoId) :-
    mine_repository(Root, RepoId, [depth(6)]).

mine_repository(Root, RepoId, Options) :-
    exists_directory(Root),
    (   mined_repo_i(RepoId, Root)
    ->  true
    ;   assertz(mined_repo_i(RepoId, Root))
    ),
    walk_tree(Root, 0, Options, Files),
    forall(member(File, Files), mine_file(File, RepoId, Root)),
    length(Files, N),
    format(atom(ObsId), 'obs_mine_~w_~w', [RepoId, N]),
    (   provenance:knowledge_item(ObsId)
    ->  true
    ;   provenance:register_knowledge(ObsId, observation,
                                      [asserted_by(file_miner), about(RepoId)])
    ),
    git_head(Root, Head),
    (   Head \= none
    ->  core:iso_now(Now),
        retractall(source_code:repo_head_i(RepoId, _, _)),
        assertz(source_code:repo_head_i(RepoId, Head, Now))
    ;   true
    ).

walk_tree(Dir, Level, Options, Files) :-
    max_depth(Options, Max),
    Level =< Max,
    directory_files(Dir, Entries),
    findall(F,
            (   member(E, Entries),
                E \= '.', E \= '..',
                atom_concat(Dir, '/', Tmp),
                atom_concat(Tmp, E, Path),
                \+ skipped_name(E),
                (   exists_directory(Path)
                ->  Level1 is Level + 1,
                    walk_tree(Path, Level1, Options, Sub),
                    member(F, Sub)
                ;   mineable(Path)
                ->  F = Path
                )
            ),
            Files).

max_depth(Options, Max) :-
    (   memberchk(depth(M), Options)
    ->  Max = M
    ;   Max = 6
    ).

skipped_name('.git').
skipped_name('node_modules').
skipped_name('__pycache__').
skipped_name('target').
skipped_name('dist').
skipped_name('.venv').
skipped_name('var').
skipped_name('.direnv').
skipped_name('result').

mineable(Path) :-
    file_name_extension(_, Ext, Path),
    language_ext(Ext, _).

language_ext(pl, prolog).
language_ext(py, python).
language_ext(el, elisp).
language_ext(lisp, common_lisp).
language_ext(js, javascript).
language_ext(ts, typescript).
language_ext(rs, rust).
language_ext(go, go).
language_ext(org, org).
language_ext(md, markdown).
language_ext(nix, nix).
language_ext(json, json).
language_ext(yaml, yaml).
language_ext(yml, yaml).

mine_file(Path, RepoId, Root) :-
    read_file_to_hash(Path, Hash),
    (   source_hash_i(Path, OldHash, _),
        OldHash == Hash
    ->  true
    ;   retractall(source_hash_i(Path, _, _)),
        assertz(source_hash_i(Path, Hash, RepoId)),
        file_name_extension(_, Ext, Path),
        language_ext(Ext, Lang),
        retractall(source_code:language_i(Path, _)),
        assertz(source_code:language_i(Path, Lang)),
        rel_path(Path, Root, RelPath),
        retractall(source_code:file_in_repo_i(Path, RepoId, _)),
        assertz(source_code:file_in_repo_i(Path, RepoId, RelPath)),
        (   catch(extract_symbols(Lang, Path, Hash), _, true)
        ->  true
        ;   true
        )
    ).

read_file_to_hash(Path, Hash) :-
    catch(read_file_to_string(Path, S, []),
          _, S = ''),
    sha_hash(S, Hash, [algorithm(sha1)]).

rel_path(Path, Root, RelPath) :-
    atom_length(Root, RL),
    sub_atom(Path, 0, RL, _, Root),
    sub_atom(Path, RL, _, 0, Rest0),
    (   sub_atom(Rest0, 0, 1, _, '/')
    ->  sub_atom(Rest0, 1, _, 0, RelPath)
    ;   RelPath = Rest0
    ).

extract_symbols(Lang, Path, Hash) :-
    handler_for(Lang, Handler),
    HandlerCall =.. [Handler, Path, Hash],
    scan_lines(Path, HandlerCall).

handler_for(prolog, prolog_handler).
handler_for(python, python_handler).
handler_for(elisp, elisp_handler).
handler_for(common_lisp, lisp_handler).
handler_for(javascript, js_handler).
handler_for(typescript, js_handler).
handler_for(rust, rust_handler).
handler_for(go, go_handler).
handler_for(nix, nix_handler).

prolog_handler(Path, Hash, Line) :-
    (   (   quoted_after_prefix(Line, ':- module(', M)
        ;   plain_after_prefix(Line, ':- module(', Rest0),
            token_upto(Rest0, M)
        ),
        add_defines(Path, M, module, Hash)
    ;   quoted_after_prefix(Line, ':- use_module(', Arg),
        add_import(Path, Arg)
    ;   quoted_after_prefix(Line, ':- consult(', Arg),
        add_import(Path, Arg)
    ;   quoted_after_prefix(Line, ':- declare_rule(', Arg),
        add_import(Path, Arg)
    ;   plain_after_prefix(Line, ':- use_module(', Arg),
        strip_tail_punct(Arg, Clean),
        add_import(Path, Clean)
    ;   plain_after_prefix(Line, ':- consult(', Arg),
        strip_tail_punct(Arg, Clean2),
        add_import(Path, Clean2)
    ).

strip_tail_punct(Atom, Clean) :-
    atom_chars(Atom, Chars),
    reverse(Chars, Rev),
    drop_space_dot(Rev, Rev1),
    balance_strip(Rev1, Rev2),
    drop_space_dot(Rev2, Rev3),
    reverse(Rev3, CleanChars),
    atom_chars(Clean, CleanChars).

drop_space_dot([C|Cs], Out) :-
    (   C == '.' ; C == ',' ; C == ' '
    ),
    !,
    drop_space_dot(Cs, Out).
drop_space_dot(Cs, Cs).

balance_strip([')'|Cs], Out) :-
    count_char([')'|Cs], ')', Close),
    count_char([')'|Cs], '(', Open),
    Close > Open,
    !,
    balance_strip(Cs, Out).
balance_strip(Chars, Chars).

count_char([], _C, 0).
count_char([C|Cs], C, N) :-
    !,
    count_char(Cs, C, N0),
    N is N0 + 1.
count_char([_|Cs], C, N) :-
    count_char(Cs, C, N).

python_handler(Path, Hash, Line) :-
    (   line_def(Line, 'def ', Name),
        add_defines(Path, Name, function, Hash)
    ;   line_def(Line, 'class ', Name),
        add_defines(Path, Name, class, Hash)
    ;   plain_after_prefix(Line, 'import ', Import),
        add_import(Path, Import)
    ;   line_def(Line, 'from ', From),
        add_import(Path, From)
    ).

elisp_handler(Path, Hash, Line) :-
    (   line_def(Line, '(defun ', Name),
        add_defines(Path, Name, function, Hash)
    ;   line_def(Line, '(defvar ', Name),
        add_defines(Path, Name, variable, Hash)
    ;   line_def(Line, '(defcustom ', Name),
        add_defines(Path, Name, option, Hash)
    ;   line_def(Line, '(defmacro ', Name),
        add_defines(Path, Name, macro, Hash)
    ).

lisp_handler(Path, Hash, Line) :-
    (   line_def(Line, '(defun ', Name),
        add_defines(Path, Name, function, Hash)
    ;   line_def(Line, '(defparameter ', Name),
        add_defines(Path, Name, variable, Hash)
    ;   line_def(Line, '(defclass ', Name),
        add_defines(Path, Name, class, Hash)
    ;   line_def(Line, '(defpackage ', Name),
        add_defines(Path, Name, package, Hash)
    ).

js_handler(Path, Hash, Line) :-
    (   line_def(Line, 'function ', Name),
        add_defines(Path, Name, function, Hash)
    ;   line_def(Line, 'class ', Name),
        add_defines(Path, Name, class, Hash)
    ;   plain_after_prefix(Line, 'import ', Import),
        add_import(Path, Import)
    ).

rust_handler(Path, Hash, Line) :-
    (   line_def(Line, 'fn ', Name),
        add_defines(Path, Name, function, Hash)
    ;   line_def(Line, 'struct ', Name),
        add_defines(Path, Name, struct, Hash)
    ;   line_def(Line, 'trait ', Name),
        add_defines(Path, Name, trait, Hash)
    ).

go_handler(Path, Hash, Line) :-
    (   line_def(Line, 'func ', Name),
        add_defines(Path, Name, function, Hash)
    ;   line_def(Line, 'type ', Name),
        add_defines(Path, Name, type, Hash)
    ;   plain_after_prefix(Line, 'import ', Import),
        add_import(Path, Import)
    ).

nix_handler(Path, Hash, Line) :-
    lhs_before_eq(Line, LHS),
    add_defines(Path, LHS, option, Hash).

extract_symbols(org, Path, Hash) :-
    assertz(documentation:doc_format_i(Path, org)),
    first_heading(Path, Title),
    add_defines(Path, Title, document_title, Hash),
    retractall(documentation:doc_section_i(Path, Title, _)),
    assertz(documentation:doc_section_i(Path, Title, Path)).
extract_symbols(markdown, Path, Hash) :-
    assertz(documentation:doc_format_i(Path, markdown)),
    first_heading(Path, Title),
    add_defines(Path, Title, document_title, Hash).
extract_symbols(json, _Path, _Hash).
extract_symbols(yaml, _Path, _Hash).

lhs_before_eq(Line, LHS) :-
    sub_atom(Line, B, _, _, '='),
    B > 0,
    sub_atom(Line, 0, B, _, LHS0),
    trim_atom(LHS0, LHS1),
    atom_length(LHS1, L),
    L > 0,
    atom_chars(LHS1, [C0|_]),
    char_type(C0, alpha),
    \+ sub_atom(LHS1, _, _, _, '=='),
    LHS = LHS1.

scan_lines(Path, Handler) :-
    setup_call_cleanup(open(Path, read, S, [encoding(utf8)]),
                       scan_stream(S, Handler),
                       close(S)).

scan_stream(S, Handler) :-
    (   read_line_to_string(S, Line),
        Line \== end_of_file
    ->  atom_string(LineA, Line),
        ignore(catch(call(Handler, LineA), _, true)),
        scan_stream(S, Handler)
    ;   true
    ).

line_def(Line, Prefix, Name) :-
    plain_after_prefix(Line, Prefix, Rest),
    token_upto(Rest, Name).

plain_after_prefix(Line, Prefix, Rest) :-
    sub_atom(Line, B, _, _, Prefix),
    atom_length(Prefix, PL),
    A is B + PL,
    sub_atom(Line, A, _, 0, Rest).

quoted_after_prefix(Line, Prefix, Arg) :-
    plain_after_prefix(Line, Prefix, Rest),
    first_quoted(Rest, Arg).

first_quoted(Atom, Arg) :-
    atom_chars(Atom, Chars),
    append(_Before, ['\''|Rest0], Chars),
    append(Mid, ['\''|_], Rest0),
    Mid \= [],
    atom_chars(Arg, Mid).

token_upto(Atom, Name) :-
    atom_chars(Atom, Chars),
    take_token(Chars, TokenChars),
    TokenChars \= [],
    atom_chars(Name, TokenChars).

take_token([], []).
take_token([C|Cs], [C|Out]) :-
    (   char_type(C, alnum)
    ;   C == '_'
    ;   C == '-'
    ),
    !,
    take_token(Cs, Out).
take_token(_, []).

add_defines(Path, Symbol, Kind, Hash) :-
    atom_length(Symbol, L),
    L > 0,
    \+ source_code:defines_i(Path, Symbol, Kind, _),
    assertz(source_code:defines_i(Path, Symbol, Kind, Hash)).

add_import(Path, What) :-
    trim_atom(What, T),
    atom_length(T, L),
    L > 0,
    \+ source_code:imports_i(Path, T),
    assertz(source_code:imports_i(Path, T)).

first_heading(Path, Title) :-
    setup_call_cleanup(open(Path, read, S, [encoding(utf8)]),
                       first_heading_stream(S, Title),
                       close(S)).

first_heading_stream(S, Title) :-
    read_line_to_string(S, Line),
    (   Line == end_of_file
    ->  Title = untitled
    ;   atom_string(LineA, Line),
        (   sub_atom(LineA, 0, 1, _, '*')
        ;   sub_atom(LineA, 0, 1, _, '#')
        )
    ->  heading_text(LineA, Title)
    ;   first_heading_stream(S, Title)
    ).

heading_text(Line, Title) :-
    atom_chars(Line, [Marker|Rest0]),
    (   member(Marker, ['*', '#'])
    ->  drop_space(Rest0, Rest1),
        (   Rest1 == []
        ->  Title = untitled
        ;   atom_chars(Title, Rest1)
        )
    ;   Title = untitled
    ).

drop_space([' '|Cs], Out) :-
    !,
    drop_space(Cs, Out).
drop_space(Cs, Cs).

trim_atom(Atom, Trimmed) :-
    atom_chars(Atom, Chars),
    reverse(Chars, R0),
    drop_space(R0, R1),
    reverse(R1, R2),
    drop_space(R2, R3),
    atom_chars(Trimmed, R3).

git_head(Root, Head) :-
    setup_call_cleanup(
        process_create(path(git), ['-C', Root, 'rev-parse', 'HEAD'],
                       [stdout(pipe(Out)), stderr(null), process(Pid)]),
        read_string(Out, _, H0),
        (   close(Out),
            process_wait(Pid, exit(0))
        )),
    split_string(H0, "\n", " \t", [H1|_]),
    atom_string(Head, H1).
