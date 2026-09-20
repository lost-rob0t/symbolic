PROLOG ?= swipl
PYTHON ?= python3
AW_URL ?= http://127.0.0.1:5600
AW_LIMIT ?= 500

.PHONY: test load clean ingest doctor ingest-activitywatch

test:
	$(PROLOG) -q -s tests/prolog/run_tests.pl -g halt

ingest-activitywatch:
	$(PYTHON) collectors/activitywatch/aw_collect.py collect --url $(AW_URL) --limit $(AW_LIMIT) --out var/observations/activitywatch.jsonl --state var/cache/aw_state.json
	$(PROLOG) -q -s prolog/symbolic.pl -g "use_module('collectors/activitywatch/aw_ingest.pl'), aw_ingest:ingest_file('var/observations/activitywatch.jsonl'), aw_ingest:ingested_count(N), format('aw_ingest: ~w events ingested~n', [N]), halt"

load:
	$(PROLOG) -q -s prolog/symbolic.pl -t "kb_status(S), print(S), halt"

clean:
	find . -name '*.pyc' -delete
	rm -rf var/observations var/cache

ingest:
	$(PYTHON) cli/symbolic.py ingest

doctor:
	$(PYTHON) cli/symbolic.py doctor
