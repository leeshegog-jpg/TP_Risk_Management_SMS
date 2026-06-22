$inboxPath  = "D:\LeeShe_Obsidian_Vault\LeeShe_Obsidian_Vault\00-Inbox"
$statusDir  = "D:\LeeShe_Obsidian_Vault\LeeShe_Obsidian_Vault\12-AgentOutputs\n8n-workflows\pipeline-status"
$vaultName  = "LeeShe_Obsidian_Vault"
$port       = 8765
$url        = "http://localhost:$port/"

$smsRoot = "D:\Github\TP_Risk_Management_SMS"

function Serve-StaticFile($response, $filePath) {
    if (-not (Test-Path $filePath -PathType Leaf)) { $response.StatusCode = 404; return }
    $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
    $ct = switch ($ext) {
        ".html" { "text/html; charset=utf-8" }
        ".css"  { "text/css; charset=utf-8" }
        ".js"   { "application/javascript; charset=utf-8" }
        ".json" { "application/json; charset=utf-8" }
        ".svg"  { "image/svg+xml" }
        ".png"  { "image/png" }
        ".jpg"  { "image/jpeg" }
        ".jpeg" { "image/jpeg" }
        ".ico"  { "image/x-icon" }
        default { "application/octet-stream" }
    }
    $bytes = [System.IO.File]::ReadAllBytes($filePath)
    $response.ContentType = $ct
    $response.ContentLength64 = $bytes.Length
    $response.OutputStream.Write($bytes, 0, $bytes.Length)
}

# HTTP Listener
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($url)
$listener.Start()

Write-Host "VRTP Incident Form Server started" -ForegroundColor Cyan
Write-Host "URL: $url"
Write-Host "Press Ctrl+C to stop."

Start-Process $url

function Build-MarkdownReport($data) {
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm"
    $lines = @(
        "# Incident Report - $($data['property']) - $($data['incident_date'])",
        "",
        "## Basic Details",
        "- Property: $($data['property'])",
        "- Date: $($data['incident_date'])",
        "- Time: $($data['incident_time'])",
        "- Location: $($data['location'])",
        "- Severity: $($data['severity'])",
        "- Ride / Asset: $($data['ride_asset'])",
        "- Reported by: $($data['reporter_name']) ($($data['reporter_role']))",
        "- Report created: $ts",
        "",
        "## People Involved",
        "- Affected person: $($data['person_type'])",
        "- Nature of injury: $($data['injury_type'])",
        "- Staff on duty: $($data['staff_present'])",
        "- Current status: $($data['person_status'])",
        "",
        "## What Happened",
        "$($data['narrative'])",
        "",
        "## Immediate Actions Taken",
        "$($data['immediate_actions'])",
        "",
        "## Regulatory Notifications",
        "- WHSQ notified: $($data['whsq_notified'])",
        "- OSR (Chapter 9A) notified: $($data['osr_notified'])",
        "",
        "## Additional Notes",
        "$($data['other_notes'])"
    )
    return $lines -join "`n"
}

try {
    while ($listener.IsListening) {
        $context  = $listener.GetContext()
        try {
        $request  = $context.Request
        $response = $context.Response
        $path     = $request.Url.LocalPath

        # CORS - allow the SMS page to call this API regardless of how it was opened
        $response.Headers.Add("Access-Control-Allow-Origin", "*")
        $response.Headers.Add("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        $response.Headers.Add("Access-Control-Allow-Headers", "Content-Type")

        # Single entry source: localhost:8765 now serves the TP Risk Management SMS
        # incident register itself, not a separate standalone form.
        if ($request.HttpMethod -eq "OPTIONS") {
            $response.StatusCode = 204

        } elseif ($request.HttpMethod -eq "GET" -and ($path -eq "/" -or $path -eq "/incident-report.html")) {
            Serve-StaticFile $response (Join-Path $smsRoot "incident-report.html")

        } elseif ($request.HttpMethod -eq "GET" -and $path -match '^/[A-Za-z0-9_\-./]+\.(html|css|js|json|svg|png|jpg|jpeg|ico)$' -and $path -notmatch '\.\.') {
            Serve-StaticFile $response (Join-Path $smsRoot ($path.TrimStart('/')))

        # Handle form submit
        } elseif ($request.HttpMethod -eq "POST" -and $path -eq "/submit") {
            $reader = New-Object System.IO.StreamReader($request.InputStream)
            $json   = $reader.ReadToEnd(); $reader.Close()
            try {
                $data = $json | ConvertFrom-Json
                $dh   = @{}
                $data.PSObject.Properties | ForEach-Object { $dh[$_.Name] = $_.Value }

                $prop     = $dh['property']
                $datePart = ($dh['incident_date'] -replace '-','')
                $locSlug  = ($dh['location'] -replace '[^a-zA-Z0-9]','-')
                if ($locSlug.Length -gt 30) { $locSlug = $locSlug.Substring(0,30) }
                $locSlug  = $locSlug.TrimEnd('-')
                $fileBase = "$prop-$datePart-$locSlug"
                $fileName = "$fileBase.md"
                $outPath  = Join-Path $inboxPath $fileName

                $markdown = Build-MarkdownReport $dh
                [System.IO.File]::WriteAllText($outPath, $markdown, [System.Text.Encoding]::UTF8)
                Write-Host "$(Get-Date -Format 'HH:mm:ss') Incident written: $fileName" -ForegroundColor Green

                # Trigger pipeline in background
                $pipelineScript = "D:\LeeShe_Obsidian_Vault\LeeShe_Obsidian_Vault\12-AgentOutputs\n8n-workflows\run-incident-pipeline.ps1"
                Start-Process powershell -ArgumentList "-ExecutionPolicy","Bypass","-File","`"$pipelineScript`"","-FilePath","`"$outPath`"" -WindowStyle Minimized

                $result = '{"ok":true,"filename":"' + $fileName + '","jobId":"' + $fileBase + '"}'
            } catch {
                $msg = ($_.Message -replace '"',"'")
                $result = '{"ok":false,"error":"' + $msg + '"}'
                Write-Host "$(Get-Date -Format 'HH:mm:ss') ERROR: $($_.Message)" -ForegroundColor Red
            }
            $buf = [System.Text.Encoding]::UTF8.GetBytes($result)
            $response.ContentType = "application/json"
            $response.ContentLength64 = $buf.Length
            $response.OutputStream.Write($buf, 0, $buf.Length)

        # Status polling endpoint
        } elseif ($request.HttpMethod -eq "GET" -and $path -match "^/status/(.+)$") {
            $jobId      = [System.Uri]::UnescapeDataString($matches[1])
            $statusFile = Join-Path $statusDir "$jobId.json"
            if (Test-Path $statusFile) {
                $statusJson = [System.IO.File]::ReadAllText($statusFile, [System.Text.Encoding]::UTF8)
            } else {
                $statusJson = '{"status":"pending","step":"waiting","message":"Waiting for pipeline to start..."}'
            }
            $buf = [System.Text.Encoding]::UTF8.GetBytes($statusJson)
            $response.ContentType = "application/json"
            $response.ContentLength64 = $buf.Length
            $response.OutputStream.Write($buf, 0, $buf.Length)

        # Combined PDF report endpoint: /report/[jobId]
        } elseif ($request.HttpMethod -eq "GET" -and $path -match "^/report/([^/]+)$") {
            $jobId      = [System.Uri]::UnescapeDataString($matches[1])
            $statusFile = Join-Path $statusDir "$jobId.json"
            $served     = $false
            if (Test-Path $statusFile) {
                $statusJson = [System.IO.File]::ReadAllText($statusFile, [System.Text.Encoding]::UTF8)
                $statusObj  = $statusJson | ConvertFrom-Json
                $outputs    = $statusObj.outputs

                function MdToHtml($md) {
                    $lines   = $md -split "`n"
                    $html    = [System.Text.StringBuilder]::new()
                    $inList  = $false
                    foreach ($line in $lines) {
                        $l = $line.TrimEnd()
                        # Strip YAML frontmatter fences
                        if ($l -eq '---') { continue }
                        if ($l -match '^created:|^type:|^source-|^status:|^tier:|^classification:|^notification-|^period-|^lessons-') { continue }
                        # Headings
                        if ($l -match '^#{4}\s+(.+)$') {
                            if ($inList) { [void]$html.Append("</ul>"); $inList=$false }
                            [void]$html.Append("<h4>$($Matches[1])</h4>")
                        } elseif ($l -match '^#{3}\s+(.+)$') {
                            if ($inList) { [void]$html.Append("</ul>"); $inList=$false }
                            [void]$html.Append("<h3>$($Matches[1])</h3>")
                        } elseif ($l -match '^#{2}\s+(.+)$') {
                            if ($inList) { [void]$html.Append("</ul>"); $inList=$false }
                            [void]$html.Append("<h2>$($Matches[1])</h2>")
                        } elseif ($l -match '^#\s+(.+)$') {
                            if ($inList) { [void]$html.Append("</ul>"); $inList=$false }
                            [void]$html.Append("<h1>$($Matches[1])</h1>")
                        } elseif ($l -match '^[-*]\s+(.+)$') {
                            if (-not $inList) { [void]$html.Append("<ul>"); $inList=$true }
                            $item = $Matches[1] -replace '\*\*(.+?)\*\*','<strong>$1</strong>'
                            [void]$html.Append("<li>$item</li>")
                        } elseif ($l -eq '') {
                            if ($inList) { [void]$html.Append("</ul>"); $inList=$false }
                            [void]$html.Append("<br>")
                        } else {
                            if ($inList) { [void]$html.Append("</ul>"); $inList=$false }
                            $p = $l -replace '\*\*(.+?)\*\*','<strong>$1</strong>'
                            [void]$html.Append("<p>$p</p>")
                        }
                    }
                    if ($inList) { [void]$html.Append("</ul>") }
                    return $html.ToString()
                }

                $sections = [System.Collections.Generic.List[string]]::new()
                $sectionDefs = @(
                    @{ key="investigation"; title="Investigation Report" },
                    @{ key="compliance";    title="Compliance Assessment" },
                    @{ key="safetyCase";    title="Safety Case Trigger Check" }
                )
                foreach ($sd in $sectionDefs) {
                    $fp = $outputs.($sd.key)
                    if ($fp -and (Test-Path $fp)) {
                        $raw = [System.IO.File]::ReadAllText($fp, [System.Text.Encoding]::UTF8)
                        $bodyHtml = MdToHtml $raw
                        $sections.Add("<section><div class='sec-header'>" + $sd.title + "</div>" + $bodyHtml + "</section>")
                    }
                }

                $propName    = $statusObj.property
                $genDate     = Get-Date -Format "dd MMMM yyyy HH:mm"
                $reportTitle = "VRTP Safety Incident Report - $propName"
                $sectionsHtml = $sections -join "`n"
                $mediaPrint  = "@media print"

                $rLines = (
                    "<!DOCTYPE html>",
                    "<html lang='en'>",
                    "<head>",
                    "<meta charset='UTF-8'>",
                    "<title>$reportTitle</title>",
                    "<style>",
                    "* { box-sizing: border-box; margin: 0; padding: 0; }",
                    "body { font-family: Segoe UI, Arial, sans-serif; font-size: 11pt; color: #1a1a1a; background: #fff; }",
                    ".no-print { background: #1a202c; color: #e2e8f0; padding: 1rem 2rem; display: flex; align-items: center; justify-content: space-between; }",
                    ".no-print h2 { font-size: 1rem; }",
                    ".btn-print { background: #c53030; color: #fff; border: none; padding: 0.6rem 1.8rem; border-radius: 4px; font-size: 0.9rem; font-weight: 700; cursor: pointer; }",
                    ".btn-print:hover { background: #9b2c2c; }",
                    ".report { max-width: 820px; margin: 2rem auto; padding: 0 2rem; }",
                    ".cover { border-bottom: 3px solid #c53030; padding-bottom: 1.5rem; margin-bottom: 2rem; }",
                    ".cover .logo-bar { display: flex; align-items: center; gap: 1rem; margin-bottom: 1rem; }",
                    ".cover .badge { background: #c53030; color: #fff; font-size: 0.7rem; font-weight: 700; padding: 3px 10px; border-radius: 3px; letter-spacing: 0.08em; }",
                    ".cover h1 { font-size: 1.6rem; color: #1a1a1a; margin-bottom: 0.3rem; }",
                    ".cover .meta { font-size: 0.85rem; color: #555; }",
                    "section { margin-bottom: 2.5rem; page-break-inside: avoid; }",
                    ".sec-header { background: #c53030; color: #fff; font-size: 0.75rem; font-weight: 700; text-transform: uppercase; letter-spacing: 0.1em; padding: 0.4rem 0.8rem; margin-bottom: 1rem; border-radius: 3px; }",
                    "h1 { font-size: 1.3rem; margin: 1rem 0 0.5rem; color: #1a1a1a; }",
                    "h2 { font-size: 1.1rem; margin: 1rem 0 0.4rem; color: #2d3748; border-bottom: 1px solid #e2e8f0; padding-bottom: 0.2rem; }",
                    "h3 { font-size: 1rem; margin: 0.8rem 0 0.3rem; color: #2d3748; }",
                    "h4 { font-size: 0.95rem; margin: 0.6rem 0 0.2rem; }",
                    "p { margin: 0.4rem 0; line-height: 1.6; }",
                    "ul { margin: 0.4rem 0 0.4rem 1.4rem; }",
                    "li { margin: 0.2rem 0; line-height: 1.5; }",
                    "strong { font-weight: 700; }",
                    ".footer { border-top: 1px solid #e2e8f0; padding-top: 0.75rem; margin-top: 2rem; font-size: 0.75rem; color: #718096; text-align: center; }",
                    "$mediaPrint { .no-print { display: none !important; } body { font-size: 10pt; } .report { margin: 0; padding: 1.5cm; max-width: 100%; } section { page-break-inside: avoid; } h2 { page-break-after: avoid; } }",
                    "</style>",
                    "</head>",
                    "<body>",
                    "<div class='no-print'>",
                    "  <h2>VRTP Incident Report - ready to save as PDF</h2>",
                    "  <button class='btn-print' onclick='window.print()'>Save as PDF / Print</button>",
                    "</div>",
                    "<div class='report'>",
                    "  <div class='cover'>",
                    "    <div class='logo-bar'><span class='badge'>SAFETY</span><span style='font-size:0.8rem;color:#718096'>VILLAGE ROADSHOW THEME PARKS</span></div>",
                    "    <h1>$reportTitle</h1>",
                    "    <div class='meta'>Generated: $genDate &nbsp;|&nbsp; Job ID: $jobId &nbsp;|&nbsp; DRAFT - PENDING HUMAN REVIEW</div>",
                    "  </div>",
                    $sectionsHtml,
                    "  <div class='footer'>This report was generated by the VRTP Multi-Agent Safety System. All outputs are drafts for Safety Manager review. No automated regulatory action has been taken.</div>",
                    "</div>",
                    "</body>",
                    "</html>"
                ) -join "`n"
                $reportHtml = $rLines
                $buf = [System.Text.Encoding]::UTF8.GetBytes($reportHtml)
                $response.ContentType = "text/html; charset=utf-8"
                $response.ContentLength64 = $buf.Length
                $response.OutputStream.Write($buf, 0, $buf.Length)
                $served = $true
            }
            if (-not $served) {
                $response.StatusCode = 404
                $errBytes = [System.Text.Encoding]::UTF8.GetBytes("Report not available. Pipeline may not be complete.")
                $response.OutputStream.Write($errBytes, 0, $errBytes.Length)
            }

        } else {
            $response.StatusCode = 404
        }
        } catch {
            Write-Host "$(Get-Date -Format 'HH:mm:ss') REQUEST ERROR: $($_.Exception.Message)" -ForegroundColor Red
            try { $response.StatusCode = 500 } catch {}
        } finally {
            try { $response.OutputStream.Close() } catch {}
        }
    }
} finally {
    $listener.Stop()
    Write-Host "Server stopped." -ForegroundColor Gray
}
