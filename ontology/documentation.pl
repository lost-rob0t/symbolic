:- module(documentation, [
              document/1,
              documents/2,
              describes/2,
              usage_example/2,
              configuration_key/2,
              documents_command/2,
              documents_api/2,
              deprecated_by/2,
              documented_by/2,
              doc_format/2,
              doc_section/3,
              doc_mentions/3
          ]).

:- use_module(core).
:- use_module(provenance).
:- use_module(filesystem).

:- dynamic documents_i/2.
:- dynamic describes_i/2.
:- dynamic usage_example_i/2.
:- dynamic configuration_key_i/2.
:- dynamic documents_command_i/2.
:- dynamic documents_api_i/2.
:- dynamic deprecated_by_i/2.
:- dynamic documented_by_i/2.
:- dynamic doc_format_i/2.
:- dynamic doc_section_i/3.
:- dynamic doc_mentions_i/3.

document(D) :-
    doc_format_i(D, _).

documents(D, E) :-
    documents_i(D, E).

describes(D, Feature) :-
    describes_i(D, Feature).

usage_example(D, Example) :-
    usage_example_i(D, Example).

configuration_key(D, Key) :-
    configuration_key_i(D, Key).

documents_command(D, Cmd) :-
    documents_command_i(D, Cmd).

documents_api(D, Api) :-
    documents_api_i(D, Api).

deprecated_by(D, Replacement) :-
    deprecated_by_i(D, Replacement).

documented_by(Entity, Doc) :-
    documented_by_i(Entity, Doc).

documented_by(Entity, Doc) :-
    documents_i(Doc, Entity).

doc_format(D, F) :-
    doc_format_i(D, F).

doc_section(D, Title, Text) :-
    doc_section_i(D, Title, Text).

doc_mentions(D, Term, Count) :-
    doc_mentions_i(D, Term, Count).
