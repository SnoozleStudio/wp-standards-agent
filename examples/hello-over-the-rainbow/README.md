# Hello, Over the Rainbow — a real before/after example

The first plugin that ships with every WordPress install is
[Hello Dolly](https://wordpress.org/plugins/hello-dolly/): a line of lyrics
in the admin, every time you open the dashboard. This example is the same
idea — **"Over the Rainbow" by Israel Kamakawiwoʻole** — written twice:

- [`before/`](before/hello-over-the-rainbow.php) — the plugin as it often
  actually looks in legacy code: no standards, no safety.
- [`after/`](after/hello-over-the-rainbow.php) — the same plugin after
  wp-standards-agent: same behavior, fully compliant.

The outputs below are real — captured by running the verification chain
against both versions (reproducible at the bottom of this file).

## Before: what the chain finds

The plugin works. But the chain refuses it at the first red:

```text
$ npm run format:all:check

{"tool":"pint","result":"fail","files":[{"path":"hello-over-the-rainbow.php","fixers":["blank_line_before_statement","single_blank_line_at_eof"]}]}
```

After Pint fixes the formatting, phpcs finds **24 errors and 1 warning**
(condensed here; the full list has 21 affected lines):

```text
 2  | ERROR | You must use "/**" style comments for a file comment
    |       | (Squiz.Commenting.FileComment.WrongStyle)
 8  | ERROR | You must use "/**" style comments for a function comment
    |       | (Squiz.Commenting.FunctionComment.WrongStyle)
 9  | ERROR | Short array syntax is not allowed
    |       | (Universal.Arrays.DisallowShortArraySyntax.Found)
 9  | ERROR | Tabs must be used to indent lines; spaces are not allowed
    |       | (Generic.WhiteSpace.DisallowSpaceIndent.SpacesUsed)  ×13
24  | ERROR | Missing doc comment for function rainbow_hello()
    |       | (Squiz.Commenting.FunctionComment.Missing)
26  | WARNING | rand() is discouraged. Use the far less predictable
    |        | wp_rand() instead. (WordPress.WP.AlternativeFunctions.rand_rand)
27  | ERROR | All output should be run through an escaping function
    |       | (WordPress.Security.EscapeOutput.OutputNotEscaped)
29  | ERROR | Opening parenthesis of a multi-line function call must be
    |       | the last content on the line
    |       | (PEAR.Functions.FunctionCallSignature.ContentAfterOpenBracket)
```

The important ones are the security findings:

| Finding | Why it matters |
| --- | --- |
| `EscapeOutput.OutputNotEscaped` | the lyric is echoed raw into admin HTML — an XSS vector the moment the source of the line changes |
| `rand()` → `wp_rand()` | `rand()` is predictable; WordPress ships a cryptographically safe replacement |
| no ABSPATH guard | the file executes its top-level code when loaded directly — the plugin contract requires the guard |
| no text domain | the strings are not translation-ready — the plugin contract requires i18n |
| closure as callback | a closure can never be removed with `remove_action()` |

## After: what changed

Same behavior, one function different, every rule satisfied:

```diff
- function rainbow_get_lyrics() {
+ function hotr_get_lyrics() {
+     // @return array<int, string> — translated lyric lines via __()
-     $lyrics = [ 'Somewhere over the rainbow, way up high', ... ];
+     $lyrics = array( __( 'Somewhere over the rainbow, way up high', 'hello-over-the-rainbow' ), ... );

- $chosen = $lyrics[ rand( 0, count( $lyrics ) - 1 ) ];
+ $chosen = $lyrics[ wp_rand( 0, count( $lyrics ) - 1 ) ];

- echo "<p id='rainbow'>$chosen</p>";
+ echo '<p id="hello-over-the-rainbow">' . esc_html( $chosen ) . '</p>';

- add_action( 'admin_notices', function () { ... } );
+ add_action( 'admin_notices', 'hotr_print_lyric' );
```

Plus, invisibly: tabs instead of spaces, `array()` instead of `[]`,
docblocks on every function, `@package` file comment, the ABSPATH guard,
and the complete plugin header (`Requires at least: 7.0`,
`Requires PHP: 8.2`, `Text Domain`, `Domain Path`).

The full chain is green:

```text
$ npm run build && npm run format:all:check
All matched files use Prettier code style!
{"tool":"pint","result":"passed"}

$ vendor/bin/phpcs --standard=phpcs.xml -d memory_limit=1024M
# no findings

$ vendor/bin/phpstan analyse --no-progress --memory-limit=1G
[OK] No errors
```

And the CI matrix of this repository runs that exact chain against
`after/` on every push — the example cannot silently rot.

## Reproduce

```bash
# From the repository root — install the kit into a copy of the after version
cp -r examples/hello-over-the-rainbow/after /tmp/hotr
./install.sh /tmp/hotr hello-over-the-rainbow hello-over-the-rainbow
cd /tmp/hotr && git init -b main && composer install && npm install
npm run build && npm run format:all:check
vendor/bin/phpcs --standard=phpcs.xml -d memory_limit=1024M
vendor/bin/phpstan analyse --no-progress --memory-limit=1G
```

Do the same with `before/` and watch the chain refuse the first version.

> The lyric set is from Israel Kamakawiwoʻole's recording of *Over the
> Rainbow*. Lyrics quoted for demonstration purposes; the strings are
> translation-ready via the `hello-over-the-rainbow` text domain.