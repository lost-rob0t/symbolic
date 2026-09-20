:- module(software_debugger, [
              debug_handler/3,
              debug_report/2
          ]).

:- use_module(library(lists)).
:- use_module('../../ontology/core').
:- use_module('../../ontology/provenance').
:- use_module('../tools/kb_tools').
:- use_module('../harness/symbolic_rlm').

debug_handler(debug(Subject), _Context, Report) :-
    debug_report(Subject, Report).

debug_report(Subject, Report) :-
    findall(cause(Cause, Evidence, ProofText),
            (   provenance:explain(candidate_cause(Subject, Cause, Evidence),
                                   Proof0),
                render_proof(Proof0, ProofText)
            ),
            Causes),
    kb_tools:kb_debug_context(Subject, debug_context{subject:Subject,
                                                     evidence:Pieces}),
    Report = debug_report{subject:Subject,
                          candidates:Causes,
                          context:Pieces}.

register_debugger :-
    symbolic_rlm:symbolic_rlm_init,
    symbolic_rlm:current_registry(Registry),
    Contract = expert_contract{id: software_debugger,
                               version: '0.1.0',
                               goal: debug/1,
                               priority: 50,
                               requires: [],
                               handler: software_debugger:debug_handler},
    expert_register(Registry, Contract, _),
    catch(symbolic_moe:moe_register(Registry, Contract,
                                    [debug, failing, broken, why, crash,
                                     error, service, daemon, cause]),
          _, true).

:- register_debugger.
