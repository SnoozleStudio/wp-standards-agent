# 2. La catena di verifica

La catena è il cuore del kit: quattro passi, in ordine, che stabiliscono se
il codice è accettabile. Vale per gli agenti e per gli umani allo stesso
modo — l'unica prova che conta è il codice di uscita di ogni comando.

## Le 4 fasi

```text
npm run build                       # build di produzione — Vite se hai asset; no-op exit 0 altrimenti
npm run format:all:check            # Prettier (JS/CSS/JSON) + Pint (PHP) in modalità dry-run
vendor/bin/phpcs --standard=phpcs.xml -d memory_limit=1024M
vendor/bin/phpstan analyse --no-progress --memory-limit=1G
```

1. **`npm run build`** — compila gli asset (se il progetto ne ha). Senza
   asset è un no-op documentato.
2. **`npm run format:all:check`** — Prettier controlla la formattazione di
   JS/CSS/JSON; Pint controlla il PHP (senza modificare nulla: `--test`).
3. **`vendor/bin/phpcs`** — WordPress Coding Standards veri e propri:
   `WordPress-Extra` + `WordPress-Docs` + `PHPCompatibility`.
4. **`vendor/bin/phpstan`** — analisi statica di livello 8 con
   `szepeviktor/phpstan-wordpress` (globi WP, `$wpdb`, `add_action`...).

## Le regole

1. **Tutte e quattro, in ordine** — fermarsi a phpcs è un campanello
   d'allarme: phpstan vede bug di tipo che phpcs non può vedere.
2. **Stop al primo rosso** — correggi e riparti dall'inizio. Non impilare
   correzioni non verificate: gli errori a cascata si mangiano il contesto
   e generano regressioni.
3. **Mai dichiarare verde senza aver eseguito** — il codice di uscita è
   l'unica prova; "probabilmente va bene" è una menzogna.
4. **Il gate la fa rispettare** — `.husky/pre-commit` esegue
   format:all:check + phpcs + phpstan a ogni commit e lo blocca se uno
   fallisce. `--no-verify` è l'eccezione documentata, non la norma.

## Quando eseguirla

- dopo ogni unità di lavoro (fix, feature, refactoring);
- prima di ogni commit o push in un progetto WordPress;
- ogni volta che l'agente dichiara di aver finito.

## Il gate husky

`npm install` attiva husky (script `prepare`), che installa il hook
`.husky/pre-commit`. Al commit, il hook esegue:

```sh
npm run format:all:check || exit 1
vendor/bin/phpcs --standard=phpcs.xml -d memory_limit=1024M || exit 1
vendor/bin/phpstan analyse --no-progress --memory-limit=1G || exit 1
```

Esempio reale — un commit con codice non conforme viene rifiutato:

```text
{"tool":"pint","result":"fail","errors":[{"path":"demo-plugin.php","message":"Parse error..."}]}
pre-commit: format check failed
```

Il commit non viene creato (exit 1). L'eccezione documentata è
`git commit --no-verify`, da usare solo con una ragione scritta.

## Note Windows

In `cmd.exe` i binari di Composer vanno richiamati con la barra inversa:
`vendor\bin\phpcs.bat` — la forma `vendor/bin/phpcs` viene interpretata come
il comando `vendor` più uno switch. Il hook husky invece esegue sotto `sh`
(Git per Windows), quindi nel file `.husky/pre-commit` le barre normali
vanno bene così come sono.

## I tool

| Tool | Ruolo | Autorità |
|------|-------|----------|
| Prettier | formatta JS/CSS/JSON | solo formattazione |
| Pint | formatta PHP | **non è l'autorità di stile** — vedi [guida 3](03-configurazione.md) |
| phpcs | WordPress Coding Standards | l'autorità di stile |
| PHPStan | analisi statica livello 8 | i bug che phpcs non vede |