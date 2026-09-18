# 7. Esempio reale: Hello, Over the Rainbow

Un esempio completo prima/dopo, riproducibile: il classico plugin
[Hello Dolly](https://wordpress.org/plugins/hello-dolly/) riscritto come
tributo a **"Over the Rainbow" di Israel Kamakawiwoʻole** — una riga di
testo nell'area di amministrazione, ogni volta che apri la dashboard.

Due versioni dello stesso plugin:

- [`before/`](../../examples/hello-over-the-rainbow/before/hello-over-the-rainbow.php) —
  codice legacy senza standard, come spesso si trova nei progetti reali;
- [`after/`](../../examples/hello-over-the-rainbow/after/hello-over-the-rainbow.php) —
  lo stesso plugin dopo wp-standards-agent: stesso comportamento, regole
  rispettate.

Gli output qui sotto sono reali: catturati eseguendo la catena di verifica
contro le due versioni (riproducibile in fondo alla pagina).

## Prima: cosa trova la catena

Il plugin funziona. Ma la catena lo rifiuta al primo rosso:

```text
$ npm run format:all:check

{"tool":"pint","result":"fail","files":[{"path":"hello-over-the-rainbow.php","fixers":["blank_line_before_statement","single_blank_line_at_eof"]}]}
```

Dopo che Pint sistema la formattazione, phpcs trova **24 errori e 1
warning** (riassunto; l'elenco completo tocca 21 righe):

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

Quelli importanti sono i rilievi di sicurezza:

| Rilievo | Perché conta |
|---------|--------------|
| `EscapeOutput.OutputNotEscaped` | il verso viene stampato grezzo nell'HTML dell'admin — un vettore XSS nel momento in cui cambia la fonte della riga |
| `rand()` → `wp_rand()` | `rand()` è prevedibile; WordPress ha un sostituto sicuro dal punto di vista crittografico |
| nessuna guardia ABSPATH | il file esegue il codice di livello top quando caricato direttamente — il contratto dei plugin richiede la guardia |
| nessun text domain | le stringhe non sono pronte per la traduzione — il contratto richiede i18n |
| closure come callback | una closure non può mai essere rimossa con `remove_action()` |

## Dopo: cosa è cambiato

Stesso comportamento, una funzione diversa, tutte le regole rispettate:

```diff
- function rainbow_get_lyrics() {
+ function hotr_get_lyrics() {
+     // @return array<int, string> — versi tradotti via __()
-     $lyrics = [ 'Somewhere over the rainbow, way up high', ... ];
+     $lyrics = array( __( 'Somewhere over the rainbow, way up high', 'hello-over-the-rainbow' ), ... );

- $chosen = $lyrics[ rand( 0, count( $lyrics ) - 1 ) ];
+ $chosen = $lyrics[ wp_rand( 0, count( $lyrics ) - 1 ) ];

- echo "<p id='rainbow'>$chosen</p>";
+ echo '<p id="hello-over-the-rainbow">' . esc_html( $chosen ) . '</p>';

- add_action( 'admin_notices', function () { ... } );
+ add_action( 'admin_notices', 'hotr_print_lyric' );
```

E, invisibile: tab al posto degli spazi, `array()` al posto di `[]`,
docblock su ogni funzione, commento di file con `@package`, guardia
ABSPATH e intestazione del plugin completa (`Requires at least: 7.0`,
`Requires PHP: 8.2`, `Text Domain`, `Domain Path`).

La catena completa è verde:

```text
$ npm run build && npm run format:all:check
All matched files use Prettier code style!
{"tool":"pint","result":"passed"}

$ vendor/bin/phpcs --standard=phpcs.xml -d memory_limit=1024M
# nessun rilievo

$ vendor/bin/phpstan analyse --no-progress --memory-limit=1G
[OK] No errors
```

E la matrice CI di questo repository esegue quella catena esatta contro
`after/` a ogni push — l'esempio non può marcire in silenzio.

## Riproduci

```bash
# Dalla radice del repository — installa il kit in una copia della versione after
cp -r examples/hello-over-the-rainbow/after /tmp/hotr
./install.sh /tmp/hotr hello-over-the-rainbow hello-over-the-rainbow
cd /tmp/hotr && git init -b main && composer install && npm install
npm run build && npm run format:all:check
vendor/bin/phpcs --standard=phpcs.xml -d memory_limit=1024M
vendor/bin/phpstan analyse --no-progress --memory-limit=1G
```

Fai lo stesso con `before/` e guarda la catena rifiutare la prima versione.

> I versi sono tratti dall'incisione di *Over the Rainbow* di Israel
> Kamakawiwoʻole. Testo citato a scopo dimostrativo; le stringhe sono
> pronte per la traduzione tramite il text domain
> `hello-over-the-rainbow`.