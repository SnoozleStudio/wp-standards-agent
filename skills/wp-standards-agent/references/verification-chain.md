# The Verification Chain

The single source of truth for the WordPress proof-of-work chain in this kit.
Every skill, installer, and doc that references the chain points here.

## The chain

Run in order for theme/plugin projects; stop at the first red:

```text
npm run build                       # production build — Vite if you have assets; no-op exit 0 otherwise
npm run format:all:check            # Prettier (JS/CSS/JSON) + Pint (PHP) dry-run
vendor/bin/phpcs --standard=phpcs.xml -d memory_limit=1024M
vendor/bin/phpstan analyse --no-progress --memory-limit=1G
```

## Rules

1. **Run all four, in order** — build → format:all:check → phpcs → phpstan. An
   abbreviated chain (e.g. stopping at phpcs) is a red flag: phpstan catches
   type bugs phpcs can't see.
2. **Stop at the first red** — fix it, then re-run from the start. Never stack
   untested fixes.
3. **Never report green without running** — the exit code is the only evidence;
   "probably fine" is a lie. This applies to agents and humans alike.
4. **The pre-commit gate enforces it** — `.husky/pre-commit` runs
   format:all:check + phpcs + phpstan and blocks the commit on failure.
   `--no-verify` is a documented escape hatch, not the norm.

## When to run it

- After every unit of work (fixes, features, refactors)
- Before every commit or push in a WordPress theme/plugin project

## Config rationale

The shipped `pint.json` disables the Laravel-preset rules that conflict with
WPCS — Pint is the formatter, **phpcs is the style authority**. The full
disable list (indentation_type, array_indentation, statement_indentation,
spaces_inside_parentheses, no_spaces_around_offset, array_syntax, yoda_style,
unary_operator_spaces, phpdoc_no_package, phpdoc_align,
no_blank_lines_after_phpdoc, function_declaration, braces_position,
class_definition, new_with_parentheses, trim_array_spaces,
binary_operator_spaces, blank_line_after_opening_tag) plus
`concat_space: one` keeps Pint from fighting WPCS over tabs vs spaces,
`array()` vs `[]`, Yoda conditions, and brace placement.

The shipped `phpstan.neon` runs level 8 with `szepeviktor/phpstan-wordpress`;
the `constant.notFound` ignore is only needed when plugin constants are
defined via `define()` with function-call values (PHPStan only auto-discovers
statically-evaluable `define()` values).

## Windows notes

Run composer bins as `vendor\bin\<tool>.bat` in cmd.exe — a forward-slash
`vendor/bin/phpcs` parses as the command `vendor` plus a switch. Git hooks
(husky) execute under sh on all platforms, so the hook script itself uses
forward slashes unchanged.