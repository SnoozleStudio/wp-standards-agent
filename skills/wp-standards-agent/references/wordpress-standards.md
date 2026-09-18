# WordPress Coding Standards — Reference

The full reference behind `SKILL.md`. Sources: developer.wordpress.org Coding
Standards (PHP), WPCS 3.0, and the WordPress Security APIs. The SKILL.md
summary is the floor; this is the ceiling.

## File mechanics

- Full tags only: `<?php` / `?>` — never `<?` or `<?=`
- Multi-line PHP in templates: tags on their own lines; omit the closing tag at EOF
- `require_once` over `include[_once]`; no parens around the path; one space
  between keyword and path
- Every file with top-level code: `if ( ! defined( 'ABSPATH' ) ) { exit; }`

## Naming

- Functions/variables/hooks: lowercase `snake_case`; never camelCase; no
  unnecessary abbreviations
- Classes/traits/interfaces/enums: `Capitalized_Words` with underscores, acronyms
  uppercase (`WP_HTTP`, `Walker_Category`)
- Constants: `ALL_CAPS_WITH_UNDERSCORES`
- Files: lowercase, hyphens; class files `class-{name}.php` (one object per file)
- Dynamic hook names: interpolation in double quotes —
  `do_action( "{$new_status}_{$post->post_type}", $post->ID )`
- Namespaces: `Prefix\Module\Sub_Module`; **`wp`/`WordPress` reserved for core**;
  namespacing does NOT cover hook names/constants/globals — still prefix them
- `use` order: classes → functions → constants; no leading backslashes

## Syntax

- Tabs for indentation (spaces only for mid-line alignment)
- Spaces both sides of operators; inside control-structure parens
  (`foreach ( $foo as $bar ) {`); after commas; `$foo['bar']` no space,
  `$foo[ $bar ]` space
- Long array syntax `array( ... )` — short `[...]` is prohibited by WPCS
- Yoda conditions for `==`/`!=`/`===`/`!==` only (constant on left); never for
  `<`/`>`
- Braces always used; `elseif` never `else if`; alternative syntax (`if: ...
  endif;`) allowed in templates
- Single quotes unless interpolating; alternate quotes to avoid escaping
- No `extract()`, `eval()`, `create_function()`, `goto`, `@` suppression; no
  short ternary `?:` (exception: `! empty()`); no assignments inside conditionals
- Closures fine as callbacks but **never** as action/filter callbacks
- Switch fall-through from a block must be explicitly commented
- `$wpdb->prepare()` placeholders: `%d` int, `%f` float, `%s` string, `%i`
  identifier (table/column, WP 6.2+); **never quote placeholders**

## OOP

- One class/interface/trait/enum per file, `class-{name}.php`
- Declare all visibility; `var` forbidden; modifier order: `abstract`/`final` →
  visibility → `static` → type
- `new Foo();` always with parens
- Type declarations: `?Type` attached; `: Type|false` no space before colon;
  gate features by PHP version

## Security — escaping matrix (output; escape at echo time, never at store)

| Function | Context |
|---|---|
| `esc_html()` | Text inside an HTML element |
| `esc_attr()` | HTML attribute values |
| `esc_url()` | URLs in any attribute (`src`, `href`) — never `esc_attr( $url )` |
| `esc_url_raw()` | Storing a URL in the DB |
| `esc_textarea()` | `<textarea>` content |
| `esc_js()` | Inline JS contexts |
| `wp_kses_post()` | Trusted-HTML post content |
| `wp_kses( $html, $allowed )` | Non-trusted HTML with an explicit allowlist |
| `(int)` / `absint()` / `(float)` | Numeric output |

Rules: escape the whole string, never fragments. `wp_localize_script()` values
need no escaping (WP handles it); `wp_json_encode()` for JSON in data
attributes. When late escaping is impossible, store variables postfixed
`_escaped`/`_safe`/`_clean`.

## Security — sanitization (input)

- `wp_unslash()` request data FIRST, then sanitize — always
- Check `isset()` / `empty()` before touching superglobals
- Functions: `sanitize_text_field()`, `sanitize_textarea_field()`,
  `sanitize_email()`, `sanitize_key()`, `sanitize_title()`,
  `sanitize_file_name()`, `sanitize_html_class()`, `sanitize_hex_color()`,
  `absint()`, `sanitize_url()`
- **Validate before sanitize**: safelists with strict checks — `1 === $input`,
  `in_array( $x, $allowed, true )`, `ctype_alnum()`, `preg_match()`. Blocklists
  are almost always wrong

## Security — nonces (CSRF)

- Purpose: CSRF protection only. NOT auth, NOT authorization — **always pair
  with `current_user_can()`**; assume nonces can be compromised
- Create: `wp_nonce_field( 'action' )` (forms), `wp_nonce_url( $url, 'action' )`
  (links), `wp_create_nonce( 'action' )` (AJAX/localize)
- Verify: `check_admin_referer( 'action' )` (admin forms, dies 403),
  `check_ajax_referer( 'action' )` (AJAX), `wp_verify_nonce( $nonce, 'action' )`
- Action strings as specific as possible — include IDs: `'trash-post_' . $post->ID`
- Guests share user ID 0 — hook `nonce_user_logged_out` for session-unique
  nonces on critical guest actions

## Security — authorization, SQL, files

- `current_user_can( 'capability' )` before every privileged action;
  `is_admin()` is NOT an auth check
- Redirects: `wp_safe_redirect()` for user-influenced URLs
- If a WP function exists, use it (`get_post_meta`, `WP_Query`, `get_posts`
  first); otherwise `$wpdb` + `$wpdb->prepare()` with unquoted placeholders.
  Never concatenate values into SQL
- `validate_file()`, `wp_handle_upload()` with mime checks; no
  `file_get_contents` on user-influenced URLs; no `exec`/`shell_exec`/
  `system`/`eval`/`create_function`/`extract`
- Secrets: never in code/options/i18n strings — `wp-config.php` constants or
  env vars

## i18n

- Every user-facing string through a translation function with the text domain
  as the LAST argument: `__( 'Text', 'domain' )`, `esc_html_e( 'Text', 'domain' )`
- **Escape + translate** for attributes: `esc_attr__()` / `esc_attr_e()`; no raw
  `__()` in HTML
- Numbered placeholders with translators comments:
  `/* translators: %s: Name */`
- `load_plugin_textdomain()` / `load_theme_textdomain()` wired on the right hook

## Hooks

- Custom hook names prefixed, documented with a full DocBlock above
  `do_action()`/`apply_filters()`; filters have no side effects
- Core hook timing: `after_setup_theme` (theme setup), `init` (CPTs, rewrites),
  `wp_enqueue_scripts` / `admin_enqueue_scripts`, `plugins_loaded`,
  `rest_api_init`

## Data

- Options API with `autoload: false` for anything large or rarely used;
  Transients for cached computed data; settings via the Settings API
  (`register_setting`)
- REST routes: `permission_callback` required for non-public data,
  `sanitize_callback` + `validate_callback` per arg, `WP_Error` with
  machine-readable codes + `status`
- Activation: defaults, CPTs, `flush_rewrite_rules()`. Deactivation: temp data
  + flush rewrites. **Deactivation is NOT uninstall** — permanent data removal
  only in `uninstall.php`, guarded by `WP_UNINSTALL_PLUGIN`

## phpcs configuration (enterprise)

```xml
<?xml version="1.0"?>
<ruleset name="Project">
    <description>Enterprise WordPress standards</description>
    <file>.</file>
    <exclude-pattern>node_modules/*</exclude-pattern>
    <exclude-pattern>vendor/*</exclude-pattern>
    <exclude-pattern>dist/*</exclude-pattern>
    <arg name="extensions" value="php"/>
    <config name="testVersion" value="8.2-"/>
    <rule ref="WordPress-Extra"/>
    <rule ref="WordPress-Docs"/>
    <rule ref="PHPCompatibility"/>
    <rule ref="WordPress.WP.I18n">
        <properties>
            <property name="text_domain" value="your-slug"/>
        </properties>
    </rule>
</ruleset>
```

Rule groups: `WordPress` (all), `WordPress-Core` (PHP standards),
`WordPress-Docs` (phpdoc), `WordPress-Extra` (best practices incl.
escaping/sanitization sniffs and a curated Universal subset, includes Core).
Add `PHPCompatibility` (with `testVersion`) for cross-version checks. Do NOT
`ref="Universal"` wholesale: its ruleset is an empty namespace container, so
PHPCS loads every sniff in it — including the mutually exclusive
`Universal.PHP.RequireExitDieParentheses` / `DisallowExitDieParentheses` pair.
Add individual Universal sniffs only when needed. `phpcbf` auto-fixes most
formatting; `WordPress.Utils.I18nTextDomainFixer` is opt-in.

## PHPStan configuration (enterprise)

`phpstan.neon` — level 8 with the WordPress extension:

```neon
includes:
    - vendor/szepeviktor/phpstan-wordpress/extension.neon

parameters:
    level: 8
    paths:
        - .
    excludePaths:
        - node_modules/*
        - vendor/*
        - dist/*
```

- `szepeviktor/phpstan-wordpress` ships WP constants, functions and globals
  (`$wpdb`, `$post`, `$wp_query`, ...) plus `add_action`/`add_filter` callable
  checks; it requires `php-stubs/wordpress-stubs` automatically
- Level 8 is the floor, not the ceiling — raise per project with extra rulesets
- Run with `--no-progress --memory-limit=1G`; part of the verification chain
  and the pre-commit gate
- WP idioms that legitimately need `ignoreErrors` get a comment explaining why —
  never a blanket `ignoreErrors` without a reason

## References

- [WordPress Coding Standards — PHP](https://developer.wordpress.org/coding-standards/wordpress-coding-standards/php/) — the normative source
- [WPCS on GitHub](https://github.com/WordPress/WordPress-Coding-Standards) — sniff list and phpcs.xml reference
- [PHP_CodeSniffer](https://github.com/PHPCSStandards/PHP_CodeSniffer) — the lint engine
- [PHPCompatibility](https://github.com/PHPCompatibility/PHPCompatibility) — cross-version sniffing (`testVersion`)
- [Common APIs Handbook — Security](https://developer.wordpress.org/apis/handbook/security/) — the authoritative WP security doctrine
- [PHPStan](https://phpstan.org) — static analysis engine; [szepeviktor/phpstan-wordpress](https://github.com/szepeviktor/phpstan-wordpress) — WordPress extension
- [Laravel Pint](https://laravel.com/docs/pint) — formatter; phpcs remains the style authority