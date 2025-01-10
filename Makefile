.PHONY: test
test:
	forge test

.PHONY: fmt
fmt:
	npm run fmt

.PHONY: fmt-check
fmt-check:
	npm run fmt-check

.PHONY: lint
lint:
	npm run lint

.PHONY: lint-check
lint-check:
	npm run lint-check