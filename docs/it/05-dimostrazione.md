# 5. Dimostrazione passo-passo

Questa è la demo del talk, riproducibile in locale: un plugin
deliberatamente non conforme viene bloccato dal gate, poi corretto, poi
accettato. Tutti gli output in questa guida sono reali — provengono da una
esecuzione verificata del kit.

## Preparazione

Crea un plugin finto con violazioni su misura (prefisso `wp_`, output non
escapato, SQL non preparato, array corti, closure come callback):

```php
<?php
/**
 * Plugin Name: Demo Plugin
 * Description: Deliberately non-compliant plugin for the wp-standards-agent demo.
 * Version: 1.0.0
 */
function wp_demo_bad() {
    $items = get_option( 'demo_items', [] );
    $item  = isset( $_GET['item'] ) ? $_GET['item'] : '';
    echo '<div>' . $item . '</div>';
    global $wpdb;
    $rows = $wpdb->get_results( "SELECT * FROM {$wpdb->prefix}posts WHERE post_status = 'publish'" );
    return $rows;
}
add_action( 'init', function () {
    update_option( 'demo_ran', true );
} );
```

Installa il kit nel plugin:

```bash
.\install.ps1 -Target .\demo-plugin -Slug demo-plugin -TextDomain demo-plugin
composer install
npm install
git init -b main
npm run prepare   # husky collega il gate
```

## Fase 1 — il gate blocca il commit

Prova a committare il codice così com'è:

```bash
git add -A
git commit -m "chore: wip"
```

Risultato reale:

```text
> demo-plugin@1.0.0 format:all:check
> npm run format:check && npm run format:php:check

> demo-plugin@1.0.0 format:php:check
> php vendor/bin/pint --test

{"tool":"pint","result":"fail","files":[{"path":"demo-plugin.php","fixers":["blank_line_before_statement","single_blank_line_at_eof"]}]}
pre-commit: format check failed
```

Il commit **non viene creato** (exit 1). La catena si è fermata al primo
rosso, come da regola: prima la formattazione.

## Fase 2 — il primo rosso si corregge

```bash
npm run format:php   # Pint sistema i fixer di formattazione
```

Ora la catena arriva a phpcs — e qui si vede il valore dell'enforcement.
Output reale (estratto):

```text
FILE: demo-plugin.php
FOUND 15 ERRORS AND 2 WARNINGS AFFECTING 12 LINES

 16 | ERROR   | Short array syntax is not allowed (Universal.Arrays.DisallowShortArraySyntax.Found)
 17 | WARNING | Processing form data without nonce verification. (WordPress.Security.NonceVerification.Recommended)
 18 | ERROR   | All output should be run through an escaping function (WordPress.Security.EscapeOutput.OutputNotEscaped), found '$item'.
 25 | ERROR   | Opening parenthesis of a multi-line function call must be the last content on the line (PEAR.Functions.FunctionCallSignature.ContentAfterOpenBracket)
 27 | ERROR   | Closing parenthesis of a multi-line function call must be on a line by itself (PEAR.Functions.FunctionCallSignature.CloseBracketLine)
```

Nota cosa ha beccato: **output non escapato** (`WordPress.Security.EscapeOutput`),
**dati di form senza nonce** (`WordPress.Security.NonceVerification`) e la
sintassi (`array()` vs `[]`). Sono esattamente le violazioni piazzate a
mano — la catena non perdona.

## Fase 3 — la versione conforme

La correzione segue le regole della [guida 4](04-agenti-e-regole.md):
escape all'output, nonce verificato, SQL preparato, prefisso corretto,
`array()` lungo, niente closure come callback.

```php
<?php
/**
 * Plugin Name: Demo Plugin
 * Description: Compliant plugin for the wp-standards-agent demo.
 * Version: 1.0.0
 * Author: Snoozle Studio
 * License: GPL-2.0-or-later
 * Text Domain: demo-plugin
 *
 * @package Demo_Plugin
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

/**
 * Fetch the published posts for the demo.
 *
 * @return array<int, object>|null Rows from the database.
 */
function demo_plugin_get_posts() {
	global $wpdb;

	return $wpdb->get_results(
		$wpdb->prepare(
			"SELECT * FROM {$wpdb->prefix}posts WHERE post_status = %s",
			'publish'
		)
	);
}

/**
 * Print the requested item.
 *
 * @return void
 */
function demo_plugin_print_item() {
	$nonce = isset( $_GET['nonce'] ) ? sanitize_text_field( wp_unslash( $_GET['nonce'] ) ) : '';
	if ( ! wp_verify_nonce( $nonce, 'demo_plugin_print_item' ) ) {
		return;
	}

	// phpcs:ignore WordPress.Security.NonceVerification.Recommended -- Nonce verified above.
	$item = isset( $_GET['item'] ) ? sanitize_text_field( wp_unslash( $_GET['item'] ) ) : '';
	echo '<div>' . esc_html( $item ) . '</div>';
}

/**
 * Mark that the demo ran.
 *
 * @return void
 */
function demo_plugin_mark_ran() {
	update_option( 'demo_plugin_ran', true );
}
add_action( 'init', 'demo_plugin_mark_ran' );
```

Due dettagli da notare:

1. **Il commento `phpcs:ignore` è giustificato.** WordPress richiede il
   nonce, ma lo sniff non collega automaticamente la lettura successiva di
   `$_GET['item']` alla verifica fatta sopra: l'ignore mirato con una
   ragione scritta è la soluzione corretta — non un ignore generico.
2. **`exit;` senza parentesi** va bene con `WordPress-Extra` (che include il
   sottoinsieme Universal curato); `array()` resta obbligatorio.

## Fase 4 — catena verde, commit accettato

```bash
npm run build
npm run format:all:check
vendor/bin/phpcs --standard=phpcs.xml -d memory_limit=1024M
vendor/bin/phpstan analyse --no-progress --memory-limit=1G
```

Output reale:

```text
> demo-plugin@1.0.0 build
> exit 0

All matched files use Prettier code style!
{"tool":"pint","result":"passed"}

Time: 336ms; Memory: 16MB          ← phpcs: nessun errore

Note: Using configuration file .../phpstan.neon.
 [OK] No errors                     ← phpstan livello 8: nessun errore
```

E il commit:

```bash
git add -A
git commit -m "chore: make demo plugin compliant"
# → il gate esegue la catena, tutto verde, commit creato
```

## Il riassunto della demo

| Momento | Comando | Risultato |
|---------|---------|-----------|
| Gate | `git commit` su codice non conforme | **bloccato** (pint fail) |
| Correzione formattazione | `npm run format:php` | primo rosso risolto |
| phpcs | `vendor/bin/phpcs` | 15 errori + 2 warning individuati |
| Codice conforme | riscrittura secondo le regole | — |
| Catena | le 4 fasi | **tutta verde** |
| Gate | `git commit` | **accettato** |

Il messaggio del talk: l'agente non è affidabile perché "sa" le regole —
è affidabile perché **non può chiudere un commit** che le viola.
Il gate è il suo partner di responsabilità.