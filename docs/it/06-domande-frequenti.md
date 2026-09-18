# 6. Domande frequenti e risoluzione dei problemi

## Installazione e requisiti

**Devo avere Vite per usare il kit?**
No. `npm run build` è un no-op (`exit 0`) per progetti senza asset. Se hai
asset, sostituisci `exit 0` con il tuo script di build (Vite, o altro).

**Quale versione di Node serve?** Node 20+ (il CI usa Node 20; l'azione
GitHub che installa Node usa il runtime Node 24 — sono cose diverse, il
requisito del kit resta 20+).

**Posso usarlo con WordPress 6.x?** Sì: `minimum_supported_wp_version` è
impostato a 7.0; se il tuo progetto supporta versioni precedenti, abbassalo
nel `phpcs.xml` del progetto. Gli sniff si adeguano.

## La catena fallisce

**`prettier --check .` si lamenta di `vendor/` o `node_modules/`.**
Il kit installa `.prettierignore` che esclude quelle cartelle. Se il file
manca (progetto preesistente), aggiungilo — senza, Prettier scandisce anche
i test fixture di PHPCS e fallisce su file che non sono tuoi.

**Pint e phpcs litigano tra loro.**
Il `pint.json` del kit disattiva le 19 regole del preset laravel che
confliggono con WPCS (tab, `array()`, Yoda, graffe...). Se vedi Pint che
riscrive codice che phpcs poi rifiuta, il `pint.json` non è quello del kit:
controlla [la guida 3](03-configurazione.md). Pint formatta, phpcs decide.

**"Missing @package tag in file comment".**
È lo sniff `Squiz.Commenting.FileComment.MissingPackageTag` di
`WordPress-Docs`: il file con codice di livello top deve avere il tag
`@package` nel commento di intestazione.

**Errori di tipo da PHPStan su costanti definite con `define()`.**
Il kit include l'ignore `constant.notFound` con commento esplicativo:
PHPStan scopre da solo solo i `define()` statici. Se non usi quel pattern,
elimina il blocco — `reportUnmatchedIgnoredErrors: false` evita falsi
positivi.

## Il gate

**Il gate non si attiva.**
Controlla che: (1) `npm install` sia stato eseguito dopo il `git init`
(husky installa i hook con lo script `prepare` — senza `.git` al momento
dell'installazione, husky non può collegarli); (2) `package.json` abbia
`"prepare": "husky"`. In caso di dubbio: `npm run prepare` a mano.

**Il gate blocca un commit che secondo me va bene.**
Esamina l'output: il gate stampa quale fase è fallita
(`pre-commit: format check failed`, `pre-commit: phpcs failed`,
`pre-commit: phpstan failed`). Corri la fase fallita a mano e correggi.
`git commit --no-verify` è l'eccezione documentata — usala solo con una
ragione scritta, non come scappatoia.

**"pre-commit: format check failed" ma Prettier dice che è tutto a posto.**
Probabilmente è Pint: il messaggio JSON di `pint --test` arriva subito
dopo. Leggi il campo `fixers` del JSON: ti dice esattamente cosa
sistemerebbe (`blank_line_before_statement`, `line_ending`...).

## Windows

**`vendor/bin/phpcs` non funziona in `cmd.exe`.**
`cmd.exe` spezza il token alla barra: `vendor/bin/phpcs` viene letto come il
comando `vendor` più uno switch. Usa `vendor\bin\phpcs.bat` (e
`vendor\bin\phpstan.bat`, `php vendor\bin\pint`). Nel hook husky invece le
barre normali vanno bene: husky esegue sotto `sh` (Git per Windows).

**I file escono con CRLF e Pint/Prettier si lamentano (`line_ending`).**
Il kit installa `.gitattributes` con `* text=auto eol=lf`: dopo
`git add --renormalize .` i checkout saranno LF. Se il problema persiste
su file già estratti: `npm run format` una volta per normalizzare, poi il
gate sarà stabile.

**`Read-Host` fallisce in uno script automatico.**
Usa i parametri non interattivi: `-Slug` e `-TextDomain` in PowerShell,
secondo e terzo argomento (o `WSA_SLUG`/`WSA_TEXT_DOMAIN`) in bash.

## Progetti preesistenti

**L'installer ha sovrascritto le mie configurazioni?**
No: ogni file già esistente viene salvato come `.bak` prima della
sostituzione. `composer.json` e `package.json` non vengono toccati:
l'installer stampa i comandi esatti per aggiungere le dipendenze a mano.

**L'installer ha creato `AGENTS.md` due volte?**
No: il blocco è delimitato dai marcatori `<!-- wp-standards-agent:start -->`
e `<!-- wp-standards-agent:end -->`. Se il marcatore esiste già, l'installer
salta. Per rimuovere: cancella il blocco tra i marcatori.

**Ho un `.gitattributes` esistente.**
L'installer lo lascia intatto e ti chiede di garantire
`*.php text eol=lf` al suo interno. Senza quella riga, git su Windows può
materializzare CRLF e il gate (Pint) si lamenterà.

## L'ambiente dell'agente

**Uso Codex/Cursor: serve installare la skill?**
No: l'installer aggiunge le regole al `AGENTS.md` del progetto, e qualunque
agente che lo legge le rispetta. La skill è per opencode e Claude Code,
dove dà anche la profondità delle reference (`references/`).

**L'agente dichiara "verde" senza aver eseguito la catena.**
Il kit non può impedirlo del tutto, ma il gate sì: un agente che dichiara
verde senza eseguire fallirà comunque al commit. Se vedi questo
comportamento, ricordagli la regola 10 del contratto: il codice di uscita
è l'unica prova.

## CI

**Gli annunci Node.js 20 deprecato nel CI.**
Sono dell'infrastruttura GitHub (le azioni `actions/checkout`/`setup-node`
v4 giravano sul runtime Node 20; il kit usa le v7, runtime Node 24). Non
riguardano il requisito Node 20 del kit.

**Come riproduce la matrice CI localmente?**
Il percorso è quello della [guida 5](05-dimostrazione.md): plugin di prova
→ installer → gate che blocca → codice conforme → catena verde → commit
accettato. La matrice CI esegue esattamente questi passi su Windows,
macOS e Linux a ogni push.