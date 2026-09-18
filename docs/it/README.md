# wp-standards-agent — Guida in italiano

Documentazione dettagliata in italiano per chi vuole far rispettare gli
[WordPress Coding Standards](https://developer.wordpress.org/coding-standards/wordpress-coding-standards/)
a ogni riga di codice scritta da un agente AI.

> **Nota sulla lingua**: i file in inglese del repository (in particolare
> `skills/wp-standards-agent/SKILL.md` e `configs/AGENTS.md.snippet`) sono la
> **fonte canonica** — vengono letti dagli agenti, che lavorano meglio in
> inglese e con la terminologia WPCS originale. Le guide qui tradotte sono
> per le persone. Se una regola inglese cambia, questa guida viene aggiornata
> nella stessa modifica.

## Indice delle guide

| # | Guida | Contenuto |
|---|-------|-----------|
| 1 | [01-installazione.md](01-installazione.md) | Requisiti e installazione su Windows, macOS e Linux |
| 2 | [02-catena-di-verifica.md](02-catena-di-verifica.md) | Le 4 fasi della catena di verifica e il gate di commit |
| 3 | [03-configurazione.md](03-configurazione.md) | phpcs, Pint e PHPStan spiegati — incluso il conflitto Pint-vs-WPCS |
| 4 | [04-agenti-e-regole.md](04-agenti-e-regole.md) | Come l'agente applica le regole: skill, AGENTS.md, escaping, nonce, i18n |
| 5 | [05-dimostrazione.md](05-dimostrazione.md) | Demo passo-passo: plugin non conforme → gate che blocca → catena verde |
| 6 | [06-domande-frequenti.md](06-domande-frequenti.md) | FAQ e risoluzione dei problemi |

## Perché esiste

Presentato a WordCamp Pisa 2026: *"How to Enforce WordPress Coding Standards
with AI Agents."* Il kit è la versione pubblica e portabile del sistema che
Snoozle Studio usa per ogni plugin e tema WordPress: WPCS 3.0, Pint,
PHPStan livello 8 e un gate git che rifiuta codice non conforme al commit.

## In sintesi

1. **La skill** (`npx skills add SnoozleStudio/wp-standards-agent`) insegna
   all'agente le regole non negoziabili.
2. **Il blocco AGENTS.md** porta le stesse regole in qualunque progetto, per
   qualunque strumento (Codex, Cursor, ...).
3. **Gli installer** (`install.ps1` / `install.sh`) copiano la configurazione
   e il gate in un plugin o tema esistente.
4. **Il gate husky** blocca il commit finché la catena di verifica non è verde
   — per agenti e umani allo stesso modo.

## Verificato su

Windows, macOS e Linux: la matrice CI di GitHub Actions esegue l'intero
percorso (installer → gate → catena) a ogni push. Vedi il README in inglese
per i dettagli.

## Collegamenti

- Repository: <https://github.com/SnoozleStudio/wp-standards-agent>
- README (inglese): <https://github.com/SnoozleStudio/wp-standards-agent/blob/main/README.md>