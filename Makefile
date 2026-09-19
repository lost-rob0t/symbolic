PROLOG ?= swipl
PYTHON ?= python3

.PHONY: test load clean ingest doctor

test:
	$(PROLOG) -q -s tests/prolog/run_tests.pl -g halt

load:
	$(PROLOG) -q -s prolog/symbolic.pl -t "kb_status(S), print(S), halt"

clean:
	find . -name '*.pyc' -delete
	rm -rf var/observations var/cache

ingest:
	$(PYTHON) cli/symbolic.py ingest

doctor:
	$(PYTHON) cli/symbolic.py doctor
