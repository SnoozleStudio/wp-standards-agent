# 1. Installazione

## Requisiti

| Strumento | Versione | Note |
|-----------|----------|------|
| PHP | 8.2+ | anche 8.4 verificato; necessario per Composer e gli strumenti di lint |
| Composer | 2.x | sulla `PATH` |
| Node.js | 20+ | con npm |
| WordPress | 7.0+ | versione minima dichiarata in `phpcs.xml` |
| Git | qualunque | necessario per il gate husky |

Non serve Vite: il passo `npm run build` della catena è un no-op (`exit 0`)
per progetti senza asset compilati. Se il tuo progetto usa Vite (o un altro
bundler), sostituisci `exit 0` con il tuo script di build reale.

## 1. La skill (la conoscenza dell'agente)

```bash
npx skills add SnoozleStudio/wp-standards-agent -a opencode
```

Per **Claude Code**: copia la cartella `skills/wp-standards-agent/` in
`~/.claude/skills/`.

Per **Codex, Cursor o qualunque altro strumento**: la skill non serve — le
regole arrivano dal blocco `AGENTS.md` che l'installer aggiunge al tuo
progetto (vedi sotto). L'agente le legge come istruzioni normali.

## 2. La configurazione e il gate (l'enforcement della macchina)

```bash
# Windows (PowerShell)
.\install.ps1 -Target percorso\del\tuo\plugin

# macOS / Linux
./install.sh percorso/del/tuo/plugin
```

L'installer:

1. copia `phpcs.xml`, `pint.json`, `phpstan.neon`, `.prettierrc`,
   `.prettierignore` e il gate `.husky/pre-commit` — le configurazioni
   esistenti vengono salvate come `.bak`, mai distrutte;
2. crea `composer.json`, `package.json`, `.gitignore` e `.gitattributes`
   se non esistono (`.gitattributes` impone LF, così Pint e Prettier non
   litigano mai con git su Windows);
3. crea o estende `AGENTS.md` con il blocco delle regole
   (riconoscibile dai marcatori `<!-- wp-standards-agent:start -->` e
   `<!-- wp-standards-agent:end -->` — se il marcatore esiste già, non duplica).

### Uso non interattivo (CI, script)

```bash
# PowerShell
.\install.ps1 -Target .\my-plugin -Slug my-plugin -TextDomain my-plugin

# bash (i tre argomenti sono: cartella, slug, text domain)
./install.sh my-plugin my-plugin my-plugin
```

Se `-Slug` (PowerShell) o il secondo argomento (bash) viene omesso,
l'installer chiede i valori interattivamente; come predefinito usa il nome
della cartella. In bash puoi anche usare le variabili d'ambiente `WSA_SLUG`
e `WSA_TEXT_DOMAIN`.

## 3. Dipendenze e gate

```bash
composer install   # se l'installer ha creato composer.json
npm install        # installa husky + prettier e attiva il gate pre-commit
```

Se il progetto aveva già `composer.json` o `package.json`, l'installer li
lascia intatti e stampa i comandi esatti da eseguire a mano:

```bash
composer require --dev laravel/pint phpcompatibility/php-compatibility phpstan/phpstan szepeviktor/phpstan-wordpress wp-coding-standards/wpcs
composer config allow-plugins.dealerdirect/phpcodesniffer-composer-installer true
npm i -D husky prettier && npm pkg set scripts.prepare=husky && npm run prepare
```

## 4. Primo giro

Esegui la catena completa (dettagli nella
[guida 2](02-catena-di-verifica.md)):

```text
npm run build
npm run format:all:check
vendor/bin/phpcs --standard=phpcs.xml -d memory_limit=1024M
vendor/bin/phpstan analyse --no-progress --memory-limit=1G
```

Da questo momento il gate blocca qualsiasi commit con codice non conforme —
scritto da te o dall'agente.

## Disinstallazione

- **Skill**: `npx skills remove wp-standards-agent` (opencode) o elimina la
  cartella dalla directory delle skill di Claude Code.
- **Configurazione**: elimina i file installati e il blocco `AGENTS.md` tra
  i marcatori `<!-- wp-standards-agent:start -->` / `:end -->`. Il gate
  husky smette di bloccare i commit quando rimuovi `.husky/pre-commit` (o
  `npx husky uninstall`).