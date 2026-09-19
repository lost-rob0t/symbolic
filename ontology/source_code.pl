:- module(source_code, [
              repository/1,
              project/1,
              source_file/1,
              test_file/1,
              language/2,
              defines/3,
              references/3,
              imports/2,
              exports/2,
              calls/3,
              implements/3,
              inherits/3,
              module_of/2,
              namespace/2,
              tests/2,
              configures/2,
              depends_on/2,
              file_in_repo/3,
              repo_head/2,
              repo_remote/3,
              repo_branch/2,
              repo_dirty/1,
              last_changed/3,
              introduced_by/3,
              changed_together/2,
              commit_affects/2,
              commit_author/3,
              commit_time/2,
              commit_touches/2
          ]).

:- use_module(core).
:- use_module(provenance).

:- dynamic repository_i/2.
:- dynamic project_i/2.
:- dynamic language_i/2.
:- dynamic defines_i/4.
:- dynamic references_i/4.
:- dynamic imports_i/3.
:- dynamic exports_i/3.
:- dynamic calls_i/4.
:- dynamic implements_i/4.
:- dynamic inherits_i/4.
:- dynamic module_i/3.
:- dynamic namespace_i/3.
:- dynamic test_file_i/2.
:- dynamic tests_i/3.
:- dynamic configures_i/3.
:- dynamic depends_on_i/3.
:- dynamic file_in_repo_i/3.
:- dynamic repo_head_i/3.
:- dynamic repo_remote_i/4.
:- dynamic repo_branch_i/3.
:- dynamic repo_dirty_i/2.
:- dynamic last_changed_i/4.
:- dynamic introduced_by_i/4.
:- dynamic commit_author_i/4.
:- dynamic commit_time_i/3.
:- dynamic commit_touches_i/3.
:- dynamic source_index_hash_i/3.

repository(R) :-
    repository_i(R, _).

project(P) :-
    project_i(P, _).

source_file(F) :-
    language_i(F, _).

test_file(F) :-
    test_file_i(F, _).

language(F, L) :-
    language_i(F, L).

defines(File, Symbol, Kind) :-
    defines_i(File, Symbol, Kind, _).

references(File, Symbol, Kind) :-
    references_i(File, Symbol, Kind, _).

imports(File, What) :-
    imports_i(File, What).

exports(File, What) :-
    exports_i(File, What).

calls(File, Caller, Callee) :-
    calls_i(File, Caller, Callee).

implements(File, Class, Iface) :-
    implements_i(File, Class, Iface).

inherits(File, Class, Base) :-
    inherits_i(File, Class, Base).

module_of(File, M) :-
    module_i(File, M).

namespace(File, N) :-
    namespace_i(File, N).

tests(TestFile, Target) :-
    tests_i(TestFile, Target, _).

configures(File, What) :-
    configures_i(File, What).

depends_on(Project, Dependency) :-
    depends_on_i(Project, Dependency).

file_in_repo(File, Repo, RelPath) :-
    file_in_repo_i(File, Repo, RelPath).

repo_head(Repo, Head, Time) :-
    repo_head_i(Repo, Head, Time).

repo_remote(Repo, Name, Url, Kind) :-
    repo_remote_i(Repo, Name, Url, Kind).

repo_branch(Repo, Branch, Time) :-
    repo_branch_i(Repo, Branch, Time).

repo_dirty(Repo, Time) :-
    repo_dirty_i(Repo, Time).

last_changed(File, Commit, Time) :-
    last_changed_i(File, Commit, Time).

introduced_by(Symbol, Commit, File, Time) :-
    introduced_by_i(Symbol, Commit, File, Time).

commit_author(Commit, Name, Email) :-
    commit_author_i(Commit, Name, Email).

commit_time(Commit, Time) :-
    commit_time_i(Commit, Time).

commit_touches(Commit, File) :-
    commit_touches_i(Commit, File).

changed_together(FileA, FileB) :-
    FileA @< FileB,
    commit_touches_i(Commit, FileA),
    commit_touches_i(Commit, FileB).

commit_affects(Commit, Subsystem) :-
    commit_touches_i(Commit, File),
    subsystem_of(File, Subsystem).

subsystem_of(File, Subsystem) :-
    module_i(File, Subsystem).
subsystem_of(File, Subsystem) :-
    namespace_i(File, Subsystem).
