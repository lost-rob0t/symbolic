:- module(provenance, [
              knowledge_item/1,
              epistemic_status/2,
              register_knowledge/3,
              register_knowledge/2,
              asserted_at/2,
              asserted_by/2,
              generator/3,
              observation/1,
              observation_of/2,
              observed_by/2,
              observed_at/2,
              observation_source/2,
              observation_payload/2,
              claim/1,
              extracted_from/2,
              extracted_by/2,
              claim_content/2,
              fact/1,
              supported_by/2,
              confidence/2,
              inference/1,
              inferred_by/2,
              depends_on/2,
              hypothesis/1,
              supersedes/2,
              kb_rule/3,
              declare_rule/3,
              retract_rule/1,
              active_rule/1,
              shadow_rule/1,
              rejected_rule/1,
              explain/2,
              proof_success/1,
              evidence_chain/2,
              render_proof/2
          ]).

:- use_module(core).

:- dynamic knowledge_i/2.
:- dynamic asserted_at_i/2.
:- dynamic asserted_by_i/2.
:- dynamic generator_i/3.
:- dynamic observation_of_i/2.
:- dynamic observed_by_i/2.
:- dynamic observed_at_i/2.
:- dynamic observation_source_i/2.
:- dynamic observation_payload_i/2.
:- dynamic extracted_from_i/2.
:- dynamic extracted_by_i/2.
:- dynamic claim_content_i/2.
:- dynamic supported_by_i/2.
:- dynamic confidence_i/2.
:- dynamic inferred_by_i/2.
:- dynamic depends_on_i/2.
:- dynamic supersedes_i/2.
:- dynamic kb_rule_i/4.
:- dynamic rule_status_i/2.

knowledge_item(K) :-
    knowledge_i(K, _).

epistemic_status(K, Status) :-
    knowledge_i(K, Status).

asserted_at(K, T) :-
    asserted_at_i(K, T).

asserted_by(K, A) :-
    asserted_by_i(K, A).

generator(K, Tool, Version) :-
    generator_i(K, Tool, Version).

register_knowledge(K, Status, Options) :-
    valid_status(Status),
    \+ knowledge_item(K),
    assertz(knowledge_i(K, Status)),
    core:iso_now(Now),
    assertz(asserted_at_i(K, Now)),
    (   memberchk(asserted_by(Agent), Options)
    ->  true
    ;   Agent = system
    ),
    assertz(asserted_by_i(K, Agent)),
    (   memberchk(generator(Tool, Version), Options)
    ->  assertz(generator_i(K, Tool, Version))
    ;   true
    ),
    (   memberchk(confidence(C), Options)
    ->  assertz(confidence_i(K, C))
    ;   true
    ),
    (   memberchk(about(Entity), Options)
    ->  assertz(observation_of_i(K, Entity))
    ;   true
    ).

register_knowledge(K, Status) :-
    register_knowledge(K, Status, []).

valid_status(observation).
valid_status(claim).
valid_status(proposal).
valid_status(fact).
valid_status(inference).
valid_status(hypothesis).
valid_status(rejected).

observation(O) :-
    epistemic_status(O, observation).

observation_of(O, E) :-
    observation_of_i(O, E).

observed_by(O, Collector) :-
    observed_by_i(O, Collector).

observed_at(O, T) :-
    observed_at_i(O, T).

observation_source(O, S) :-
    observation_source_i(O, S).

observation_payload(O, P) :-
    observation_payload_i(O, P).

claim(C) :-
    epistemic_status(C, claim).

extracted_from(C, O) :-
    extracted_from_i(C, O).

extracted_by(C, X) :-
    extracted_by_i(C, X).
extracted_by(C, X) :-
    \+ extracted_by_i(C, _),
    asserted_by_i(C, X).

claim_content(C, T) :-
    claim_content_i(C, T).

fact(F) :-
    epistemic_status(F, fact).

supported_by(K, E) :-
    supported_by_i(K, E).

confidence(K, C) :-
    confidence_i(K, C).

inference(I) :-
    epistemic_status(I, inference).

inferred_by(I, Rule) :-
    inferred_by_i(I, Rule).

depends_on(I, P) :-
    depends_on_i(I, P).

hypothesis(H) :-
    epistemic_status(H, hypothesis).

supersedes(New, Old) :-
    supersedes_i(New, Old).

kb_rule(Id, Head, Body) :-
    kb_rule_i(Id, _M, Head, Body),
    \+ rule_status_i(Id, rejected),
    \+ rule_status_i(Id, shadow).

declare_rule(Id, Head, Body) :-
    prolog_load_context(module, M),
    retractall(kb_rule_i(Id, _, _, _)),
    assertz(kb_rule_i(Id, M, Head, Body)),
    (   rule_status_i(Id, _)
    ->  true
    ;   assertz(rule_status_i(Id, active))
    ).

retract_rule(Id) :-
    retractall(kb_rule_i(Id, _, _, _)),
    retractall(rule_status_i(Id, _)),
    assertz(rule_status_i(Id, rejected)).

active_rule(Id) :-
    rule_status_i(Id, active).

shadow_rule(Id) :-
    rule_status_i(Id, shadow).

rejected_rule(Id) :-
    rule_status_i(Id, rejected).

proof_success(true).
proof_success(leaf(_, _)).
proof_success(builtin(_, _)).
proof_success(proof(_, _, _)).
proof_success((A, B)) :-
    proof_success(A),
    proof_success(B).

:- meta_predicate explain(0, ?).

explain(Goal0, Proof) :-
    strip_module(Goal0, CX, Goal),
    prove(CX, Goal, Proof).

prove(CX, Goal, proof(Goal, rule(Id), SubProofs)) :-
    kb_rule_i(Id, M, Head, Body),
    \+ rule_status_i(Id, rejected),
    \+ rule_status_i(Id, shadow),
    copy_term(Head-Body, HeadCopy-BodyCopy),
    HeadCopy = Goal,
    prove_body(M, BodyCopy, SubProofs).
prove(CX, Goal, leaf(CX, Goal)) :-
    catch(clause(CX:Goal, true), _, fail),
    !.
prove(CX, Goal, leaf(M, Goal)) :-
    predicate_property(CX:Goal, imported_from(M)),
    catch(clause(M:Goal, true), _, fail),
    !.
prove(CX, Goal, leaf(visible(CX), Goal)) :-
    predicate_property(CX:Goal, visible),
    catch(CX:Goal, _, fail),
    \+ predicate_property(CX:Goal, built_in),
    !.
prove(_CX, Goal, builtin(Goal)) :-
    predicate_property(Goal, built_in),
    catch(Goal, _, fail).

prove_body(M, true, true) :-
    !.
prove_body(M, (A, B), (PA, PB)) :-
    !,
    prove_body(M, A, PA),
    prove_body(M, B, PB).
prove_body(M, Goal, Proof) :-
    kb_rule_i(Id, M, Head, Body),
    \+ rule_status_i(Id, rejected),
    \+ rule_status_i(Id, shadow),
    copy_term(Head-Body, HeadCopy-BodyCopy),
    HeadCopy = Goal,
    prove_body(M, BodyCopy, SubProofs),
    Proof = proof(Goal, rule(Id), SubProofs).
prove_body(M, Goal, leaf(M, Goal)) :-
    catch(clause(M:Goal, true), _, fail),
    !.
prove_body(M, Goal, leaf(M2, Goal)) :-
    predicate_property(M:Goal, imported_from(M2)),
    catch(clause(M2:Goal, true), _, fail),
    !.
prove_body(M, Goal, leaf(visible(M), Goal)) :-
    predicate_property(M:Goal, visible),
    catch(M:Goal, _, fail),
    \+ predicate_property(M:Goal, built_in),
    !.
prove_body(_M, Goal, builtin(Goal)) :-
    predicate_property(Goal, built_in),
    catch(Goal, _, fail).

evidence_chain(K, chain(K, Children)) :-
    findall(Child,
            (   supported_by_i(K, E),
                evidence_chain(E, Child)
            ;   extracted_from_i(K, O),
                evidence_chain(O, Child)
            ;   depends_on_i(K, P),
                evidence_chain(P, Child)
            ;   inferred_by_i(K, Rule),
                chain_rule(Rule, Child)
            ),
            Children).

chain_rule(Rule, rule_ref(Rule)).

render_proof(Proof, Lines) :-
    render_proof(Proof, 0, Lines0),
    flatten(Lines0, LinesFlat),
    atomic_list_concat(LinesFlat, '\n', Lines).

render_proof(true, _, []) :-
    !.
render_proof(leaf(M, Goal), D, [Pad, Text]) :-
    !,
    pad(D, Pad),
    format(atom(Text), '~w  [fact ~w]', [Goal, M]).
render_proof(builtin(Goal), D, [Pad, Text]) :-
    !,
    pad(D, Pad),
    format(atom(Text), '~w  [builtin]', [Goal]).
render_proof(proof(Goal, rule(Id), Children), D, [Pad, Head, Subs]) :-
    !,
    pad(D, Pad),
    format(atom(Head), '~w  [rule ~w]', [Goal, Id]),
    D1 is D + 1,
    render_children(Children, D1, Subs).
render_proof((A, B), D, Lines) :-
    !,
    render_proof(A, D, LA),
    render_proof(B, D, LB),
    append(LA, LB, Lines).

render_children((A, B), D, Lines) :-
    !,
    render_children(A, D, LA),
    render_children(B, D, LB),
    append(LA, LB, Lines).
render_children(Child, D, Lines) :-
    render_proof(Child, D, Lines).

pad(0, '') :-
    !.
pad(D, Pad) :-
    N is 2 * D,
    length(Spaces, N),
    maplist(=(0' ), Spaces),
    atom_chars(Pad, Spaces).
