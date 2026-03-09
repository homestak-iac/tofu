# tofu Makefile

.PHONY: help install-deps

help:
	@echo "tofu - OpenTofu VM provisioning"
	@echo ""
	@echo "  make install-deps  - Install OpenTofu"
	@echo ""
	@echo "Secrets Management:"
	@echo "  Secrets are managed in the config repository."
	@echo "  See: ../config/ or https://github.com/homestak/config"
	@echo ""
	@echo "  cd ../config && make decrypt"

install-deps:
	@echo "Installing OpenTofu..."
	@apt-get update -qq
	@apt-get install -y -qq apt-transport-https ca-certificates curl gnupg > /dev/null
	@install -m 0755 -d /etc/apt/keyrings
	@curl -fsSL https://get.opentofu.org/opentofu.gpg | tee /etc/apt/keyrings/opentofu.gpg >/dev/null
	@curl -fsSL https://packages.opentofu.org/opentofu/tofu/gpgkey | gpg --no-tty --batch --dearmor -o /etc/apt/keyrings/opentofu-repo.gpg 2>/dev/null || true
	@chmod a+r /etc/apt/keyrings/opentofu.gpg /etc/apt/keyrings/opentofu-repo.gpg
	@echo "deb [signed-by=/etc/apt/keyrings/opentofu.gpg,/etc/apt/keyrings/opentofu-repo.gpg] https://packages.opentofu.org/opentofu/tofu/any/ any main" > /etc/apt/sources.list.d/opentofu.list
	@apt-get update -qq
	@apt-get install -y -qq tofu > /dev/null
	@echo "Done."
