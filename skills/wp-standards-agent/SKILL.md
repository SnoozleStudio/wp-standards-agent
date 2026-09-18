---
name: wp-standards-agent
description: Enforce WordPress Coding Standards (WPCS) on every line an agent writes. Use when creating or editing WordPress plugins and themes — PHP files, hooks, escaping, sanitization, nonces, i18n, SQL, REST routes. Loads the non-negotiable standards, the escaping matrix, and the 4-step verification chain (build → format:all:check → phpcs → phpstan), and wires the gate into git so non-compliant code can't land. Triggers on "new plugin", "new theme", "WPCS", "WordPress coding standards", "make this WP-compliant", "is this escaping right", "pass phpcs".
---

# WordPress Coding Standards Enforcement

You are writing WordPress code that must survive Theme Review and Plugin Review, run
on PHP 8.2+, and pass the verification chain. These rules are non-negotiable —
violations are review failures, security holes, or both. Load
`references/wordpress-standards.md` for the full reference and
`references/verification-chain.md` for the gate.

## The contract

1. **Escape at output, never at store.** Every echo of dynamic data passes through
   the escaping matrix — `esc_html()` (text), `esc_attr()` (attributes),
   `esc_url()` (URLs — never `esc_attr( $url )`), `esc_textarea()`,
   `wp_kses_post()` (trusted HTML). Escape the whole string, never fragments.
2. **Sanitize input, validate first.** `wp_unslash()` request data FIRST, then
   sanitize (`sanitize_text_field()`, `absint()`, `sanitize_email()`,
   `sanitize_key()`, ...). Validate before sanitize with safelists and strict
   checks — blocklists are almost always wrong.
3. **SQL only through `$wpdb->prepare()`** with unquoted `%s`/`%d`/`%f`/`%i`
   placeholders. Prefer WP APIs (`get_post_meta`, `WP_Query`) over raw SQL.
   Never concatenate values into SQL.
4. **Nonces are CSRF-only.** Every state-changing form gets a nonce
   (`wp_nonce_field()`/`check_admin_referer()`), paired with
   `current_user_can( 'capability' )` — a nonce is NOT authorization, and
   `is_admin()` is NOT an auth check.
5. **Prefix everything** — functions, classes, namespaces, options, transients,
   hook names. Project prefix ≥ 4 chars, never `wp_`, `__`, `_`. Classes are
   `Class_Name` (one per file, `class-{name}.php`); files lowercase with hyphens.
6. **i18n always** — every user-facing string through `__()`, `esc_html_e()`,
   `esc_attr_e()` with the text domain as the LAST argument. Translators comments
   for numbered placeholders. Escape + translate in attributes.
7. **Correct hook timing** — `after_setup_theme` (theme setup), `init` (CPTs,
   rewrites), `wp_enqueue_scripts`, `rest_api_init` (REST routes),
   `plugins_loaded`. Custom hooks prefixed and documented.
8. **Lifecycle contract** — activation sets defaults + flushes rewrites;
   deactivation clears temp data + flushes rewrites; **deactivation is NOT
   uninstall** — permanent data removal only in `uninstall.php`, guarded by
   `WP_UNINSTALL_PLUGIN`. ABSPATH guard on every file with top-level code.
9. **REST** — `permission_callback` on every non-public route,
   `validate_callback` + `sanitize_callback` per arg, `WP_Error` with
   machine-readable codes and a status.
10. **Never fake measurements** — a lint result, test result, or build that was
    not actually run is a lie. The exit code is the only evidence.

## WPCS syntax floor

Tabs for indentation; `array( ... )` never `[...]`; Yoda conditions for
`==`/`!=`/`===`/`!==`; braces always, `elseif` never `else if`; single quotes
unless interpolating; no `extract()`/`eval()`/`create_function()`/`@`; closures
never used as action/filter callbacks (they can't be removed).

## The verification chain

After every unit of work and before every commit, run in order, stopping at the
first red — never stack untested fixes:

```text
npm run build                       # production build — Vite if you have assets; no-op exit 0 otherwise
npm run format:all:check            # Prettier (JS/CSS/JSON) + Pint (PHP) dry-run
vendor/bin/phpcs --standard=phpcs.xml -d memory_limit=1024M
vendor/bin/phpstan analyse --no-progress --memory-limit=1G
```

Details, config rationale, and the escape hatches: `references/verification-chain.md`.

## Using this kit

- **opencode / Claude Code**: this skill auto-loads on WordPress tasks.
- **Any agent (Codex, Cursor, ...)**: the portable guardrail block in
  `configs/AGENTS.md.snippet` is appended to the project's `AGENTS.md` by the
  installer — the same rules, tool-agnostic.
- **The gate**: the installer drops `phpcs.xml`, `pint.json`, `phpstan.neon`
  (level 8 + `szepeviktor/phpstan-wordpress`) and the `.husky/pre-commit` hook
  into the project, so `git commit` refuses non-compliant code locally —
  the agent's accountability partner.

## Project type notes

- **Plugin**: main file is the ONLY file with the plugin header; `includes/`
  for classes and shared functions, `admin/` (still capability-checked) and
  `public/` split; `languages/` for the text domain path.
- **Theme**: `functions.php` boots via `require` chain; templates output escaped
  data only; `wp_enqueue_scripts` for assets, manifest-driven enqueue for
  build tools.