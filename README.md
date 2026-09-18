# wp-standards-agent

**Enforce WordPress Coding Standards on every line your AI agent writes.**

A drop-in kit that turns any coding agent (opencode, Claude Code, Codex, Cursor —
or any tool that reads `AGENTS.md`) into a WordPress standards enforcer: the
non-negotiable rules, the escaping matrix, the 4-step verification chain, and a
git gate that refuses non-compliant code at commit time.

Built from the system Snoozle Studio runs every WordPress plugin and theme
through — WPCS 3.0, Pint, PHPStan level 8, husky. Presented at WordCamp Pisa
2026: *"How to Enforce WordPress Coding Standards with AI Agents."*

## What you get

| Piece | What it does |
|---|---|
| `skills/wp-standards-agent/SKILL.md` | The discipline — auto-loads in opencode / Claude Code whenever WordPress code is written or reviewed |
| `skills/wp-standards-agent/configs/AGENTS.md.snippet` | The same rules as a portable block for **any** agent tool (Codex, Cursor, ...) |
| `skills/wp-standards-agent/configs/phpcs.xml` | WordPress-Extra + Docs + PHPCompatibility (testVersion 8.2-) |
| `skills/wp-standards-agent/configs/pint.json` | Pint tuned so it never fights phpcs — phpcs is the style authority |
| `skills/wp-standards-agent/configs/phpstan.neon` | PHPStan level 8 with `szepeviktor/phpstan-wordpress` |
| `skills/wp-standards-agent/configs/package.json` + `.husky/pre-commit` | The gate: `git commit` blocks on format/phpcs/phpstan failures |
| `install.ps1` / `install.sh` | One command: drop everything into an existing plugin or theme |
| `skills/wp-standards-agent/references/` | The full standards + verification-chain reference the skill loads |

## Install

### 1. The skill (agent knowledge)

**opencode:**

```bash
npx skills add snoozlestudio/wp-standards-agent -a opencode
```

**Claude Code:** copy `skills/wp-standards-agent/` into `~/.claude/skills/`.

**Codex / Cursor / any tool:** the installer appends
`skills/wp-standards-agent/configs/AGENTS.md.snippet` to your project's
`AGENTS.md` — your agent reads it as normal instructions.

### 2. The tooling + gate (machine enforcement)

```bash
# Windows
.\install.ps1 -Target path\to\your-plugin

# macOS / Linux
./install.sh path/to/your-plugin
```

The installer copies `phpcs.xml`, `pint.json`, `phpstan.neon`, `.prettierrc`,
`.prettierignore`, and the `.husky/pre-commit` gate (backing up any existing
configs as `.bak`), creates `composer.json` / `package.json` / `.gitignore` /
`.gitattributes` when absent, and gates your `AGENTS.md`. Then:

```bash
composer install
npm install     # wires the pre-commit gate via husky
```

### 3. Run the chain

```text
npm run build                       # Vite production build
npm run format:all:check            # Prettier + Pint dry-run
vendor/bin/phpcs --standard=phpcs.xml -d memory_limit=1024M
vendor/bin/phpstan analyse --no-progress --memory-limit=1G
```

In order, stop at the first red. From now on, the gate enforces it on every
commit — for your agents and your humans alike.

## Prove it

Try it on a deliberately non-compliant plugin: write PHP with unescaped output,
an unpadded SQL query, a `wp_`-prefixed function, a closure as an action
callback — then ask your agent to fix it and watch the chain and the gate
refuse anything less than clean. That's the demo.

## Repository layout

```
├── skills/wp-standards-agent/            # the skill, self-contained
│   ├── SKILL.md                          # the discipline (opencode / Claude Code)
│   ├── references/                       # standards + verification-chain reference
│   └── configs/                          # drop-in tooling + AGENTS.md.snippet
├── install.ps1 / install.sh              # installers (identical behavior)
├── AGENTS.md                             # maintenance rules for this repo
└── LICENSE                               # MIT
```

## Requirements

- PHP 8.2+ (Composer on PATH)
- Node 18+ (npm)
- WordPress 6.8+ target projects

## License

MIT — see [LICENSE](LICENSE). WordPress Coding Standards are
[GPL](https://github.com/WordPress/WordPress-Coding-Standards); the configs
here are your own project's files to do with as you please.