.DEFAULT_GOAL := build
.SHELLFLAGS := -eu -o pipefail -c
SHELL := /bin/bash

NPM ?= npm
PYTHON ?= python3

.PHONY: build build-backend build-frontend build-frontend-admin type-check \
        type-check-frontend type-check-frontend-admin api-test-collect \
        lint unit-test integration-test semantic-check

build: build-backend build-frontend build-frontend-admin

build-backend:
	cd back && bash ./mvnw -B -DskipTests compile

build-frontend:
	cd frontend && $(NPM) ci && $(NPM) run build

build-frontend-admin:
	cd frontend-admin && $(NPM) ci && $(NPM) run build

type-check: type-check-frontend type-check-frontend-admin

type-check-frontend:
	cd frontend && $(NPM) ci && npx vue-tsc -b

type-check-frontend-admin:
	cd frontend-admin && $(NPM) ci && npx vue-tsc --noEmit

api-test-collect:
	cd api_testcases && $(PYTHON) -m pip install -r requirements.txt && $(PYTHON) -m pytest --collect-only --tb=short

# These targets fail closed until the repository owner supplies real commands.
lint:
	$(error lint command is not configured; do not treat this target as passed)

unit-test:
	$(error unit-test command is not configured; do not treat this target as passed)

integration-test:
	$(error integration-test command is not configured; do not treat this target as passed)

semantic-check:
	$(error semantic-check command is not configured; do not treat this target as passed)
