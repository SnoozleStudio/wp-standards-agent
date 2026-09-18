# 3. La configurazione: phpcs, Pint e PHPStan

Questo capitolo spiega i tre file di configurazione che l'installer copia nel
progetto. È anche il materiale del talk: il conflitto Pint-vs-WPCS è il
problema che tutti incontrano quando aggiungono un formatter automatico a un
progetto WordPress.

## `phpcs.xml` — WordPress Coding Standards

```xml
<ruleset name="demo-plugin">
	<file>.</file>
	<exclude-pattern>node_modules/*</exclude-pattern>
	<exclude-pattern>vendor/*</exclude-pattern>
	<exclude-pattern>dist/*</exclude-pattern>

	<arg name="extensions" value="php"/>
	<arg value="ps"/>

	<config name="testVersion" value="8.2-"/>
	<config name="minimum_supported_wp_version" value="7.0"/>

	<rule ref="WordPress-Extra"/>
	<rule ref="WordPress-Docs"/>
	<rule ref="PHPCompatibility"/>

	<rule ref="WordPress.WP.I18n">
		<properties>
			<property name="text_domain" value="demo-plugin"/>
		</properties>
	</rule>
</ruleset>
```

I tre gruppi di regole:

- **`WordPress-Extra`** — le best practice: escaping, sanitizzazione, nonce,
  naming, incluso il sottoinsieme curato di `Universal`;
- **`WordPress-Docs`** — i docblock (l'agente deve documentare ciò che scrive);
- **`PHPCompatibility`** — con `testVersion 8.2-` vieta sintassi o funzioni
  non disponibili su PHP 8.2+.

La proprietà `text_domain` alimenta lo sniff `WordPress.WP.I18n`: ogni stringa
traducibile deve usare il text domain del progetto come ultimo argomento.

### L'errore da non fare: `ref="Universal"` a tutto

Non aggiungere mai `Universal` intero al ruleset. Il suo ruleset è un
contenitore vuoto: PHPCS carica **ogni** sniff del namespace, inclusa la
coppia mutuamente esclusiva `RequireExitDieParentheses` /
`DisallowExitDieParentheses`. Il risultato è un conflitto irrisolvibile.
`WordPress-Extra` include già il sottoinsieme curato; aggiungi sniff
`Universal.*` singoli solo quando ti servono davvero.

## `pint.json` — il conflitto Pint-vs-WPCS

Laravel Pint usa il preset `laravel`, che è scritto per Laravel: spazi
invece dei tab, `[]` invece di `array()`, condizioni non-Yoda, parentesi
attaccate. Tutto il contrario di WPCS. Se lanci Pint con il preset
predefinito su un progetto WordPress, ti riscrive il codice in modo che
**phpcs lo rifiuta**, e i due tool litigano all'infinito.

La soluzione è il `pint.json` incluso nel kit: la regola d'oro è
**Pint formatta, phpcs decide**. Il file disattiva le 19 regole del preset
che confliggono con WPCS:

```json
{
  "preset": "laravel",
  "rules": {
    "indentation_type": false,
    "array_indentation": false,
    "statement_indentation": false,
    "spaces_inside_parentheses": false,
    "no_spaces_around_offset": false,
    "array_syntax": false,
    "yoda_style": false,
    "unary_operator_spaces": false,
    "phpdoc_no_package": false,
    "phpdoc_align": false,
    "no_blank_lines_after_phpdoc": false,
    "function_declaration": false,
    "braces_position": false,
    "binary_operator_spaces": false,
    "class_definition": false,
    "new_with_parentheses": false,
    "trim_array_spaces": false,
    "blank_line_after_opening_tag": false,
    "concat_space": { "spacing": "one" }
  }
}
```

In pratica: Pint continua a sistemare ordine di import, spazi vuoti e
lacune di formattazione innocue, ma non tocca tab, `array()`, Yoda e
posizione delle graffe — che restano dominio di phpcs. E l'ultima regola,
`concat_space: one`, fa sì che Pint uniformi la concatenazione a un solo
spazio attorno al punto, come vuole WPCS.

### Perché non solo Pint o solo phpcs?

- phpcs controlla e **segnala**, ma corregge poco (phpcbf corregge le cose
  banali); non è un formatter vero.
- Pint formatta alla grande, ma non ha le regole WordPress (naming,
  escaping, nonce, i18n).
- Insieme: Pint rende il codice uniforme, phpcs lo rende conforme, phpstan
  lo rende corretto.

## `phpstan.neon` — analisi statica livello 8

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
    reportUnmatchedIgnoredErrors: false
    ignoreErrors:
        - identifier: constant.notFound
```

- **Livello 8** è il massimo di PHPStan — il pavimento, non il soffitto.
- `szepeviktor/phpstan-wordpress` porta funzioni, costanti e globi di
  WordPress (`$wpdb`, `$post`, `$wp_query`...) e controlla i callback di
  `add_action`/`add_filter`. Trascina automaticamente
  `php-stubs/wordpress-stubs`.
- L'ignore `constant.notFound` serve solo se definisci costanti con
  `define()` e valori da funzioni (`plugin_dir_url()`...): PHPStan scopre
  da solo solo i `define()` statici. Se non usi quel pattern, elimina il
  blocco (con `reportUnmatchedIgnoredErrors: false` non dà errori).

### La regola d'oro degli ignore

Ogni `ignoreErrors` deve avere un commento che spiega perché esiste.
Mai `ignoreErrors` generici senza motivo: un'analisi statica che bolla tutto
è peggio di una che non c'è.

## Perché `minimum_supported_wp_version 7.0`

La versione minima dichiarata guida gli sniff `WordPress.WP.*` che
dipendono dalla versione (funzioni deprecate, comportamenti cambiati).
Il kit dichiara 7.0 come baseline: se il tuo progetto supporta versioni
precedenti, abbassala con consapevolezza — gli sniff si adeguano.

## File associati

- `.prettierignore` — esclude `node_modules/`, `vendor/`, `dist/` dal
  controllo Prettier (senza, `prettier --check .` scandisce anche i test
  fixture di PHPCS e fallisce su file che non sono tuoi).
- `.gitattributes` — `* text=auto eol=lf`: forza LF nel checkout, così
  Pint/Prettier non litigano con `core.autocrlf` su Windows.
- `.husky/pre-commit` — il gate (vedi [guida 2](02-catena-di-verifica.md)).