.PHONY: test
test:
	forge test

.PHONY: test-huff
test-huff:
	@for file in test/*.t.huff test/foundry/*.t.huff; do hnc $$file test || exit 1; done

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