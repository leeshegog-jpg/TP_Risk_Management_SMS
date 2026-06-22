# VRTP Agent Investigation Pipeline (local automation)

This folder holds the local, agent-driven incident pipeline that powers the **"🔬 Run Agent Investigation"** button in `incident-report.html`. It is not a static web page — it is a Windows-only PowerShell service plus two Claude-driven agents (Investigation Agent, Compliance Agent) and a Safety Case Trigger check, all reading and writing into an Obsidian vault.

Reference: [VRTP Safety Case Specialist skill](../) for the s 608R / Chapter 9A logic the Compliance Agent applies.

## What it does

1. `start-incident-form.ps1` opens an HTTP listener on `localhost:8765`, serves a richer intake form, and exposes three endpoints: `POST /submit`, `GET /status/{jobId}`, `GET /report/{jobId}`.
2. On submit, it writes the incident to Markdown in the vault's `00-Inbox` and kicks off `run-incident-pipeline.ps1` in the background.
3. `run-incident-pipeline.ps1` runs the Investigation Agent, then the Compliance Agent (Claude Sonnet via the Anthropic API), archives the source file, and — if the compliance output signals an ADI on a Major Amusement Park property — triggers a Safety Case Trigger check.
4. Progress is written to `pipeline-status/{jobId}.json`, which both the standalone form and `incident-report.html` poll every 5 seconds.

## Why it can't run as part of the hosted site

GitHub Pages (and any static host) only serves files — it cannot run a PowerShell HTTP listener or call the Anthropic API server-side. This pipeline only works when run locally, on a Windows machine with:

- PowerShell 5.1+
- The `ANTHROPIC_API_KEY` environment variable set (User scope)
- Access to the Obsidian vault at the path configured at the top of each script (`$vaultRoot` / `$inboxPath` / `$statusDir`) — update these if your vault lives somewhere else

## How `incident-report.html` uses it

The "🔬 Run Agent Investigation" button in the incident form POSTs to `http://localhost:8765/submit` and polls `/status/{jobId}`. If the local server isn't running, the page tells you and you can still fall back to **Save Incident**, which writes a standard register entry with no agent run. Once the pipeline completes, the page links the resulting investigation/compliance/safety-case files and a printable report (`/report/{jobId}`) back onto the incident record — but those links only resolve on the machine that ran the pipeline.

## Running it

```powershell
$env:ANTHROPIC_API_KEY = "sk-ant-..."   # once per session, or set at User scope permanently
powershell -ExecutionPolicy Bypass -File .\start-incident-form.ps1
```

Leave the window open — closing it stops the listener and the agent run.
