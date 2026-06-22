# VRTP Agent Investigation Pipeline (local automation)

This folder holds the local, agent-driven incident pipeline that powers the **"🔬 Run Agent Investigation"** button in `incident-report.html`. It is not a static web page — it is a Windows-only PowerShell service plus two Claude-driven agents (Investigation Agent, Compliance Agent) and a Safety Case Trigger check, all reading and writing into an Obsidian vault.

Reference: [VRTP Safety Case Specialist skill](../) for the s 608R / Chapter 9A logic the Compliance Agent applies.

## Single entry source

`start-incident-form.ps1` no longer serves its own copy of the intake form. `http://localhost:8765/` now serves `incident-report.html` itself, straight out of this repo, so there is exactly one form: the SMS register. The PowerShell script's only jobs are (a) acting as a tiny static file server for `incident-report.html` and its assets (`sms.css`, `sms-shared.js`, etc.) and (b) running the agent pipeline API. There is no separate "VRTP Incident Report" page to keep in sync any more.

## What it does

1. `start-incident-form.ps1` opens an HTTP listener on `localhost:8765`. `GET /` and `GET /incident-report.html` serve the SMS register page from `$smsRoot` (set at the top of the script — defaults to `D:\Github\TP_Risk_Management_SMS`); any other `GET` for a file that exists under `$smsRoot` (css/js/html/etc.) is served the same way. Three API endpoints remain: `POST /submit`, `GET /status/{jobId}`, `GET /report/{jobId}`.
2. On submit, it writes the incident to Markdown in the vault's `00-Inbox` and kicks off `run-incident-pipeline.ps1` in the background.
3. `run-incident-pipeline.ps1` runs the Investigation Agent, then the Compliance Agent (Claude Sonnet via the Anthropic API), archives the source file, and — if the compliance output signals an ADI on a Major Amusement Park property — triggers a Safety Case Trigger check.
4. Progress is written to `pipeline-status/{jobId}.json`, which `incident-report.html` polls every 5 seconds.

## Why it can't run as part of the hosted site

GitHub Pages (and any static host) only serves files — it cannot run a PowerShell HTTP listener or call the Anthropic API server-side. This pipeline only works when run locally, on a Windows machine with:

- PowerShell 5.1+
- The `ANTHROPIC_API_KEY` environment variable set (User scope)
- Access to the Obsidian vault at the path configured at the top of each script (`$vaultRoot` / `$inboxPath` / `$statusDir`) — update these if your vault lives somewhere else

## How `incident-report.html` uses it

The "🔬 Run Agent Investigation" button in the incident form POSTs to `http://localhost:8765/submit` and polls `/status/{jobId}`. If the local server isn't running, the page tells you and you can still fall back to **Save Incident**, which writes a standard register entry with no agent run. Once the pipeline completes, the page links the resulting investigation/compliance/safety-case files and a printable report (`/report/{jobId}`) back onto the incident record — but those links only resolve on the machine that ran the pipeline.

Open `incident-report.html` either way you like — directly as a file, or via `http://localhost:8765/` once the server is running — it is the same file in both cases. Opening it through `localhost:8765` is the recommended path: the page and the pipeline API then share an origin, so the browser never has to make a cross-origin call to reach `/submit`.

## Running it

```powershell
$env:ANTHROPIC_API_KEY = "sk-ant-..."   # once per session, or set at User scope permanently
powershell -ExecutionPolicy Bypass -File .\start-incident-form.ps1
```

This opens `http://localhost:8765/` in your browser automatically — that page is the SMS incident register. Leave the window open — closing it stops the listener and the agent run.

If `$smsRoot` at the top of the script doesn't point at your checkout of this repo, update it before running.
