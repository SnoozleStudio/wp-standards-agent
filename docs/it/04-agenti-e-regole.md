# 4. Agenti e regole: come l'agente applica gli standard

Il kit funziona su due livelli: la **conoscenza** (cosa l'agente sa) e
l'**enforcement** (cosa la macchina rifiuta). Questo capitolo spiega il
primo livello — e la matrice di escaping, che è il cuore della sicurezza
WordPress.

## I due livelli

| Livello | Strumento | Cosa fa |
|---------|-----------|---------|
| Conoscenza | `SKILL.md` (opencode/Claude Code) | l'agente carica le regole quando tocca codice WordPress |
| Conoscenza | blocco `AGENTS.md` | le stesse regole per qualunque agente, in qualunque progetto |
| Enforcement | `.husky/pre-commit` + la catena | il commit non parte se il codice non è conforme |

Il trucco è la ridondanza: se l'agente dimentica una regola, la catena la
becca; se la catena non è configurata, l'agente la conosce comunque.

## Cosa vede l'agente (SKILL.md)

La skill `wp-standards-agent` si attiva da sola (auto-matching sulla
`description`) quando il compito riguarda plugin o temi WordPress, e impone
il contratto in 10 punti:

1. **Escape all'output, mai allo store** — ogni dato dinamico in output
   passa dalla matrice di escaping (sotto).
2. **Sanitizza l'input, valida prima** — `wp_unslash()` PRIMA, poi
   `sanitize_text_field()`, `absint()`, ecc. Valida con liste bianche e
   controlli stretti; le blacklist sono quasi sempre sbagliate.
3. **SQL solo con `$wpdb->prepare()`** — placeholder non quotati
   `%s`/`%d`/`%f`/`%i`. Preferisci le API WP (`get_post_meta`, `WP_Query`).
   Mai concatenare valori dentro SQL.
4. **Nonce solo per CSRF** — ogni form che cambia stato ha un nonce,
   **sempre** accoppiato a `current_user_can( 'capability' )`. Un nonce
   non è autorizzazione, e `is_admin()` non è un controllo di auth.
5. **Prefissi ovunque** — funzioni, classi, namespace, opzioni, transient,
   nomi di hook. Prefisso di progetto ≥ 4 caratteri; mai `wp_`, `__`, `_`.
6. **i18n sempre** — ogni stringa visibile passa da `__()`, `esc_html_e()`,
   `esc_attr_e()` con il text domain come ULTIMO argomento.
7. **Hook al momento giusto** — `after_setup_theme` (setup del tema),
   `init` (CPT, rewrite), `wp_enqueue_scripts`, `rest_api_init`,
   `plugins_loaded`.
8. **Contratto di ciclo di vita** — attivazione: default + flush rewrites;
   disattivazione: dati temporanei + flush rewrites; **la disattivazione
   NON è la disinstallazione** — i dati permanenti si eliminano solo in
   `uninstall.php`, protetto da `WP_UNINSTALL_PLUGIN`. Guardia `ABSPATH`
   su ogni file con codice di livello top.
9. **REST** — `permission_callback` su ogni rotta non pubblica,
   `validate_callback` + `sanitize_callback` per argomento, `WP_Error` con
   codici machine-readable e status.
10. **Mai misurazioni finte** — un lint, un test o una build "probabilmente
    verdi" sono una menzogna. Il codice di uscita è l'unica prova.

## La matrice di escaping (tabella da ricordare)

| Funzione | Contesto |
|----------|----------|
| `esc_html()` | testo dentro un elemento HTML |
| `esc_attr()` | valori di attributi HTML |
| `esc_url()` | URL in qualunque attributo (`src`, `href`) — mai `esc_attr( $url )` |
| `esc_url_raw()` | URL da salvare nel DB |
| `esc_textarea()` | contenuto di `<textarea>` |
| `esc_js()` | contesti JS inline |
| `wp_kses_post()` | contenuto HTML di fiducia (post) |
| `wp_kses( $html, $allowed )` | HTML non di fiducia con allowlist esplicita |
| `(int)` / `absint()` / `(float)` | output numerici |

Regole operative:

- **Escape sull'intera stringa, mai sui frammenti** — non spezzare
  `esc_attr()` attorno a una concatenazione.
- `wp_localize_script()` non richiede escaping (lo fa WP);
  `wp_json_encode()` per JSON dentro attributi `data-*`.
- Se l'escaping tardivo non è possibile, le variabili si chiamano con
  suffisso `_escaped`/`_safe`/`_clean`.

## Sanitizzazione (input)

- `wp_unslash()` sui dati di request PRIMA, poi sanitizza — sempre.
- Verifica `isset()` / `empty()` prima di toccare i superglobali.
- Funzioni: `sanitize_text_field()`, `sanitize_textarea_field()`,
  `sanitize_email()`, `sanitize_key()`, `sanitize_title()`,
  `sanitize_file_name()`, `sanitize_html_class()`, `sanitize_hex_color()`,
  `absint()`, `sanitize_url()`.
- **Valida prima di sanitizzare**: liste bianche con controlli stretti —
  `1 === $input`, `in_array( $x, $allowed, true )`, `ctype_alnum()`,
  `preg_match()`.

## Nonce e autorizzazione

- Creazione: `wp_nonce_field( 'action' )` (form), `wp_nonce_url( $url,
  'action' )` (link), `wp_create_nonce( 'action' )` (AJAX/localize).
- Verifica: `check_admin_referer( 'action' )` (form admin, muore con 403),
  `check_ajax_referer( 'action' )` (AJAX), `wp_verify_nonce( $nonce,
  'action' )` (generico).
- Le stringhe di azione devono essere specifiche, con gli ID:
  `'trash-post_' . $post->ID`.
- Gli ospiti condividono l'user ID 0: per azioni critiche di ospiti aggancia
  `nonce_user_logged_out` per nonce unici per sessione.

## L'AGENTS.md portabile

L'installer aggiunge al progetto un blocco delimitato da
`<!-- wp-standards-agent:start -->` ... `<!-- wp-standards-agent:end -->`.
Qualunque agente che legge `AGENTS.md` (Codex, Cursor, Claude Code,
opencode) trova le stesse regole e la stessa catena di verifica — nessuna
skill da installare. È il modo in cui il kit funziona anche negli strumenti
che non hanno un sistema di skill.

## La regola d'oro dell'agente

Quando l'agente incontra codice non conforme, la catena è la sua bussola:
correggi → riesegui dalla prima fase → solo verde dichiara fine. Se non può
eseguire la catena (manca un tool), deve dirlo — non può dichiarare verde
per fede.