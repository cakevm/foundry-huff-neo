.PHONY: test
test:
	forge test

.PHONY: fmt
fmt:
	forge fmt

.PHONY: fmt-check
fmt-check:
	forge fmt --check

.PHONY: lint
lint:
	npm run lint

.PHONY: lint-check
lint-check:
	npm run lint-check