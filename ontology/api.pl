:- module(api_ontology, [
              api/1,
              endpoint/3,
              method/2,
              parameter/4,
              returns/3,
              requires_auth/2,
              defined_by/2,
              documented_by/2,
              api_format/2,
              schema_key/3
          ]).

:- use_module(core).
:- use_module(provenance).

:- dynamic api_i/2.
:- dynamic endpoint_i/4.
:- dynamic method_i/3.
:- dynamic parameter_i/5.
:- dynamic returns_i/3.
:- dynamic requires_auth_i/2.
:- dynamic defined_by_i/2.
:- dynamic documented_by_api_i/2.
:- dynamic api_format_i/2.
:- dynamic schema_key_i/4.

api(A) :-
    api_i(A, _).

endpoint(A, Path, Op) :-
    endpoint_i(A, Path, _, Op).

method(Endpoint, M) :-
    method_i(Endpoint, M).

parameter(Endpoint, Name, In, Type) :-
    parameter_i(Endpoint, Name, In, Type).

returns(Endpoint, Code, Schema) :-
    returns_i(Endpoint, Code, Schema).

requires_auth(Endpoint, Scheme) :-
    requires_auth_i(Endpoint, Scheme).

defined_by(Api, Source) :-
    defined_by_i(Api, Source).

documented_by(Api, Doc) :-
    documented_by_api_i(Api, Doc).

api_format(A, F) :-
    api_format_i(A, F).

schema_key(Api, Pointer, Value) :-
    schema_key_i(Api, Pointer, Value).
