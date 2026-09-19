# Symbolic — AGENTS.md

Canonical local-first meta knowledge base for the operator's computing
environment. Prolog is authoritative. LLMs propose; Prolog disposes.

## Workflow mode

- This project runs **Auto-RAGE** (user-selected 2026-09-19): the complete
  ADADR loop (Analyze -> Design -> Adversarial review -> recorded Decision ->
  Realize) is executed by the worker without human approval gates. Decision
  records go in `docs/architecture.org`. Do not silently switch to ADADR.

## Git policy

- Remote host: **GitHub** (`git@github.com:lost-rob0t/symbolic.git`),
  user-selected 2026-09-19. Forgejo (`git.starintel.actor`) is NOT used for
  this repository.
- Incremental commits per slice. Never commit secrets. Never commit
  `var/`, `.prolog/runs/`, or verifier runtime state.

## Verification policy (mandatory)

- Every file-changing task uses `prolog-verify`:
  `prolog-verify init --task <id>` -> `prolog-verify observe -- <cmd>` for
  each real check -> `prolog-verify check` before claiming completion.
- Prolog tests use plunit: `make test` (runs `tests/prolog/run_tests.pl`).
- Never assert `verified(true)` or other self-certifying facts.
- Never weaken invariants to pass the gate. Do not fabricate test results.

## Architecture invariants

- One world model: every integration projects into the shared ontology under
  `ontology/`. No isolated per-integration databases.
- Epistemic lattice is explicit: observation -> claim -> proposal -> fact,
  plus inference, hypothesis, rule. Never flatten these.
- Provenance is mandatory: knowledge without `asserted_at/asserted_by`,
  extraction source, or inference rule is second-class and must not be
  promoted.
- All derived knowledge that agents rely on is a declared `kb_rule/3` so
  `explain/2` can produce a proof graph. Undeclared helper predicates are
  plumbing, not knowledge.
- LLM output is ALWAYS candidate knowledge (`proposal`), never written
  directly into the production KB. Council thresholds (4/5 additive, 5/5
  breaking) are Prolog rules in `ontology/learning.pl`.
- Secrets: collectors must redact before persisting or transmitting.
  Never ingest env dumps, tokens, keys, cookies.

## Layout map

- `ontology/` foundational domain modules (core, provenance, learning, ...)
- `prolog/` loader (`symbolic.pl`), `facts/`, `rules/` (declared kb_rules),
  `experts/`, `governance/`, `generated/`
- `collectors/` machine capture (linux, systemd, proc, git, code, docs,
  packages, network, activitywatch, opencode, emacs, notifications)
- `extractors/` deterministic + llm
- `indexers/` code, docs, api
- `rlm/` Prolog-RLM harness (tools, experts, prompts)
- `council/` proposals, ballots
- `server/`, `cli/` local API + `symbolic` CLI
- `integrations/` emacs, zara, opencode, android
- `tests/` plunit + collector + integration + fixtures
- `var/` runtime state (gitignored)
