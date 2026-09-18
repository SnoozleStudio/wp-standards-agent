# AGENTS.md

This repo dogfoods the kit it ships. The rules in `skills/wp-standards-agent/SKILL.md`
apply to any PHP in this repo, and the verification chain in
`references/verification-chain.md` applies to any changes you make here.

## Maintenance rules

- `skills/wp-standards-agent/configs/` is the canonical source for the tooling —
  keep the four configs (phpcs.xml, pint.json, phpstan.neon, composer.json)
  mutually consistent.
- `skills/wp-standards-agent/configs/AGENTS.md.snippet` and
  `skills/wp-standards-agent/SKILL.md` must not drift: same rules, different
  audiences (tools vs agents). Update both in the same change.
- English files are canonical; `docs/it/` is the human-facing Italian
  adaptation of the same rules and commands. A rule change in English must
  be mirrored in `docs/it/` in the same change; `docs/it/` never invents
  rules the English sources don't have. Skill files and `AGENTS.md.snippet`
  stay English on purpose (agent-facing) — documented in `docs/it/README.md`.
- The skill folder is self-contained on purpose — the skills CLI installs only
  `skills/wp-standards-agent/`, so references and configs must stay inside it.
- `install.ps1` and `install.sh` must behave identically: same files, same
  prompts, same next-steps output. A change to one requires the other.
- Tokens `{{SLUG}}` / `{{TEXT_DOMAIN}}` are substituted by the installers —
  never ship a config with a hard-coded slug.
- The verification claim of the kit is only as strong as its own proof: any
  change to configs or installers must be re-run against a scratch project
  before commit (see README "Prove it").
- `examples/` content must stay chain-green: the CI `example` job installs
  the kit into `examples/hello-over-the-rainbow/after/` and requires the
  full chain to pass. `before/` stays deliberately non-compliant — its
  findings are documented in the example README and must not drift from
  what the chain actually reports.
- `.github/workflows/verify.yml` re-runs installer → gate → chain on
  ubuntu-latest, macos-latest and windows-latest for every push. A
  config/installer change that is not CI-green is not done — the matrix is the
  cross-platform proof. The Windows leg must run `install.ps1`, the POSIX legs
  `install.sh`; keep the steps OS-agnostic (shell: bash everywhere).