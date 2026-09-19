:- module(agent_ontology, [
              agent/1,
              agent_kind/2,
              agent_model/2,
              agent_provider/2,
              tool_call/4,
              agent_identity/2,
              llm_extraction/3
          ]).

:- use_module(core).
:- use_module(provenance).

:- dynamic agent_i/2.
:- dynamic agent_model_i/2.
:- dynamic agent_provider_i/2.
:- dynamic tool_call_i/5.
:- dynamic agent_identity_i/2.
:- dynamic llm_extraction_i/3.

agent(A) :-
    agent_i(A, _).

agent_kind(A, K) :-
    agent_i(A, K).

agent_model(A, M) :-
    agent_model_i(A, M).

agent_provider(A, P) :-
    agent_provider_i(A, P).

tool_call(Id, Agent, Tool, Args) :-
    tool_call_i(Id, Agent, Tool, Args).

agent_identity(A, Id) :-
    agent_identity_i(A, Id).

llm_extraction(Id, Model, PromptVersion) :-
    llm_extraction_i(Id, Model, PromptVersion).
