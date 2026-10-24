.PHONY: test
test:
	forge test

.PHONY: vm-huff
vm-huff:
	python3 scripts/build_vm_macros.py

# Fails when src/vm.huff differs from what the generator makes of lib/forge-std
.PHONY: vm-huff-check
vm-huff-check: vm-huff
	git diff --exit-code src/vm.huff

.PHONY: test-huff
test-huff:
	@for file in test/*.t.huff test/foundry/*.t.huff; do hnc $$file test || exit 1; done

# Fork tests read mainnet through the `mainnet` RPC alias, set by MAINNET_HTTP
.PHONY: test-huff-fork
test-huff-fork:
	@test -n "$$MAINNET_HTTP" || (echo "MAINNET_HTTP must be set to a mainnet RPC URL" && exit 1)
	@for file in test/foundry/fork/*.t.huff; do hnc $$file test || exit 1; done

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