# Changelog

## Unreleased

### Changed
- Update stale paths for multi-org migration (#72)
  - `site-config` → `config` in docs and Makefile
  - GitHub URLs updated to `homestak-iac/tofu`

### Fixed
- Use `config/.state/` for runtime markers instead of `config/state/`
- Fix cloud-init bootstrap path and config marker location

## v0.53 - 2026-03-06

### Changed
- Bump bpg/proxmox provider from 0.94.0 to 0.97.1 (#57)

### Removed
- Remove unused `var.ssh_user` from generic environment — was declared but never referenced (iac-driver#275)

## v0.52 - 2026-03-02

### Breaking

- **User-owned path model**: Cloud-init runcmd uses `HOMESTAK_APPLY=config` instead of explicit `./run.sh config` calls; config-complete marker path changed to `~/etc/state/config-complete.json` (bootstrap#75)

## v0.51 - 2026-02-28

No changes.

## v0.50 - 2026-02-22

### Added
- Wire `dns_servers` variable through generic env to proxmox-vm module — enables explicit DNS config via cloud-init (iac-driver#229)

### Changed
- Update `var.images` mapping for simplified packer naming: `debian-12`, `debian-13`, `pve-9` (packer#48)
- Cloud-init injects `HOMESTAK_SERVER` + `HOMESTAK_TOKEN` (was `HOMESTAK_SPEC_SERVER` + `HOMESTAK_IDENTITY` + `HOMESTAK_AUTH_TOKEN`) (iac-driver#187, iac-driver#188)
- Add controller-based bootstrap to cloud-init runcmd for pull mode (iac-driver#163)

### Documentation
- Add dependency update validation guidance to CLAUDE.md (homestak-dev#221)
- Update provider version reference to note Dependabot management (homestak-dev#221)
  - Curls `install.sh` from controller, clones repos via HTTPS
  - Passes `HOMESTAK_REF=_working` to clone controller's working branch (not master)
  - Passes `SKIP_SITE_CONFIG=1` (VMs get config from pre-resolved specs)
  - Fix SSH key indent in cloud-init user-data (6→10 spaces)
  - Redirect config output to `/var/log/homestak-config.log`

## v0.45 - 2026-02-02

### Theme: Create Integration

Integrates create phase with config mechanism for automatic spec discovery on first boot.

### Added
- Add `spec_server` variable for Create → Specify flow (#174)
  - Injects `HOMESTAK_SPEC_SERVER`, `HOMESTAK_IDENTITY`, `HOMESTAK_AUTH_TOKEN` via cloud-init
  - Writes environment variables to `/etc/profile.d/homestak.sh`
  - Auto-fetches spec on first boot (idempotent)
- Add `auth_token` field to `vms` object for posture-based authentication

## v0.44 - 2026-02-02

- Release alignment with homestak v0.44

## v0.43 - 2026-02-01

- Release alignment with homestak v0.43

## v0.42 - 2026-01-31

- Release alignment with homestak v0.42

## v0.41 - 2026-01-31

### Added
- Add `automation_user` variable for non-root SSH access (#33)
  - Cloud-init creates non-root user (default: `homestak`) for VM SSH access
  - Separates VM automation user from PVE host SSH user (root)
  - Required for n3-full recursive PVE validation

## v0.39 - 2026-01-22

### Fixed
- Add ssh_host variable and node block to generic environment provider
  - Enables remote SSH connections for file uploads on non-localhost nodes
  - Required for recursive-pve scenarios running tofu on inner PVE

## v0.26 - 2026-01-17

- Release alignment with homestak v0.26

## v0.25 - 2026-01-16

- Release alignment with homestak v0.25

## v0.24 - 2026-01-16

- Release alignment with homestak v0.24

## v0.18 - 2026-01-13

- Release alignment with homestak v0.18

## v0.16 - 2026-01-11

- Bump bpg/proxmox provider to 0.92.0 (validated via vm-roundtrip)
- Release alignment with homestak v0.16

## v0.13 - 2026-01-10

- Release alignment with homestak-dev v0.13

## v0.12 - 2025-01-09

- Release alignment with homestak-dev v0.12

## v0.11 - 2026-01-08

- Release alignment with iac-driver v0.11

## v0.10 - 2026-01-08

### Documentation

- Add third-party acknowledgments for bpg/proxmox provider
- Fix CLAUDE.md: add missing `gateway` field in vms variable

### CI/CD

- Add GitHub Actions workflow for `tofu fmt` and `tofu validate`

### Housekeeping

- Enable secret scanning and Dependabot

## v0.9 - 2026-01-07

### Features

- Add `debian-13-pve` to default images map for nested PVE testing

### Housekeeping

- Add `**/data/` to .gitignore (TF_DATA_DIR cache from direct tofu runs)

## v0.8 - 2026-01-07

No changes - version bump for unified release.

## v0.7 - 2026-01-06

### Bug Fixes

- Fix gateway bug in VM provisioning - now correctly passed to cloud-init (closes #20)

### Changes

- Remove `.states/` directory and gitignore entry (moved to iac-driver)
- Update docs: replace deprecated `pve` with real node names
- Code review improvements (closes #17, #18, #19)
- Update Dependabot config for current directory structure

## v0.6 - 2026-01-06

### Phase 5: Generic Environment

- Add `envs/generic/` - receives pre-resolved config from iac-driver
- **Breaking:** Delete `modules/config-loader/` (replaced by iac-driver ConfigResolver)
- **Breaking:** Delete `envs/dev/`, `envs/k8s/`, `envs/nested-pve/`, `envs/test/`
- Keep `envs/common/` and `envs/prod/` (legacy)
- tofu now acts as "dumb executor" - all config logic in iac-driver

## v0.5 - 2026-01-04

Consolidated pre-release with config-loader module.

### Highlights

- config-loader module for YAML configuration
- Loads from site-config/nodes/*.yaml and envs/*.yaml
- Resolves secrets by key reference

### Changes

- Documentation improvements
- Cross-repo consistency updates

## v0.3.0 - 2026-01-04

### Features

- Add `config-loader` module for YAML configuration
  - Loads from `site-config/nodes/*.yaml` and `site-config/envs/*.yaml`
  - Resolves secret references from `site-config/secrets.yaml`
  - Merge order: site.yaml → nodes/{node}.yaml → envs/{env}.yaml → secrets.yaml
- All environments now use config-loader instead of tfvars

### Changes

- **BREAKING**: Remove tfvars support in favor of YAML configuration

## v0.2.0 - 2026-01-04

### Features

- Add configurable `ssh_user` for Proxmox provider (supports non-root SSH)
- Bump bpg/proxmox provider to 0.91.0

### Changes

- **BREAKING**: Move secrets to [site-config](https://github.com/homestak-dev/site-config) repository
- Environment tfvars now in `site-config/envs/*/terraform.tfvars`
- Remove in-repo SOPS encryption (Makefile, .githooks, .sops.yaml, *.tfvars.enc)

## v0.1.0-rc1 - 2026-01-03

### Modules

- **proxmox-vm**: VM provisioning with cloud-init
- **proxmox-file**: Cloud image management (local or URL source)
- **proxmox-sdn**: VXLAN SDN networking

### Environments

- **dev**: Development environment with SDN isolation
- **k8s**: Kubernetes environment with SDN isolation
- **nested-pve**: Debian 13 (Trixie) VM for PVE 9.x installation
- **test**: Parameterized test VM (works on any PVE host)

### Infrastructure

- 3-level configuration inheritance (defaults, cluster, node)
- Branch protection enabled (PR reviews for non-admins)
- Dependabot for provider updates
- Tested via iac-driver nested-pve-roundtrip scenario
