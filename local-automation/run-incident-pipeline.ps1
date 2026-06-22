param([Parameter(Mandatory=$true)][string]$FilePath)

$vaultRoot      = "D:\LeeShe_Obsidian_Vault\LeeShe_Obsidian_Vault"
$invPromptPath  = "$vaultRoot\10-Documents\Skills\system-prompts\investigation-agent-prompt.txt"
$compPromptPath = "$vaultRoot\10-Documents\Skills\system-prompts\compliance-agent-prompt.txt"
$statusDir      = "$vaultRoot\12-AgentOutputs\n8n-workflows\pipeline-status"
$apiKey         = [System.Environment]::GetEnvironmentVariable("ANTHROPIC_API_KEY", "User")
$model          = "claude-sonnet-4-5"
$apiUrl         = "https://api.anthropic.com/v1/messages"

if (-not $apiKey) { Write-Host "ERROR: ANTHROPIC_API_KEY not set." -ForegroundColor Red; exit 1 }

$fileName = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
$rawName  = [System.IO.Path]::GetFileName($FilePath)
$dateStr  = Get-Date -Format "yyyy-MM-dd"

$propertyMap = @{ "WnW"="WETNWILD"; "WetNWild"="WETNWILD"; "MovieWorld"="MWORLD"; "SeaWorld"="SEAWORLD"; "SkyPoint"="SKYPOINT"; "Studios"="STUDIOS"; "Paradise"="PARADISE"; "TopGolf"="TOPGOLF"; "AOS"="AOS"; "Resort"="RESORT" }
$property = "Unknown"
foreach ($k in $propertyMap.Keys) { if ($fileName -imatch [regex]::Escape($k)) { $property = $propertyMap[$k]; break } }

$invOutPath  = "$vaultRoot\06-Investigations\$dateStr-INVESTIGATION-$fileName.md"
$compOutPath = "$vaultRoot\05-Compliance\Notifications\$dateStr-COMPLIANCE-$fileName.md"
$archivePath = "$vaultRoot\01-Incidents\$property\$dateStr-$rawName"
$statusFile  = "$statusDir\$fileName.json"
$scOutPath   = ""

Write-Host "$(Get-Date -Format 'HH:mm:ss') VRTP Incident Pipeline" -ForegroundColor Cyan
Write-Host "$(Get-Date -Format 'HH:mm:ss') File: $rawName | Property: $property"

# Status helpers
function Write-Status($step, $msg, $state, $extra) {
    $obj = @{
        status    = $state
        step      = $step
        message   = $msg
        updated   = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        fileName  = $fileName
        property  = $property
        outputs   = $extra
    }
    $json = $obj | ConvertTo-Json -Depth 4
    [System.IO.File]::WriteAllText($statusFile, $json, [System.Text.Encoding]::UTF8)
}

$outputs = @{ investigation=""; compliance=""; safetyCase=""; archived="" }
Write-Status "starting" "Pipeline started" "running" $outputs

function Read-SafeText($path) {
    $bytes = [System.IO.File]::ReadAllBytes($path)
    $enc   = New-Object System.Text.UTF8Encoding($false, $false)
    $text  = $enc.GetString($bytes)
    $sb    = New-Object System.Text.StringBuilder
    $i = 0
    while ($i -lt $text.Length) {
        $c = $text[$i]
        if ([char]::IsHighSurrogate($c)) { $i += 2 } else { [void]$sb.Append($c); $i++ }
    }
    return $sb.ToString()
}

$incidentContent = Read-SafeText $FilePath
$invPrompt       = Read-SafeText $invPromptPath
$compPrompt      = Read-SafeText $compPromptPath

$headers = @{ "x-api-key" = $apiKey; "anthropic-version" = "2023-06-01"; "content-type" = "application/json" }

function Invoke-Agent($SystemPrompt, $UserMessage, $Label) {
    Write-Host "$(Get-Date -Format 'HH:mm:ss') Running $Label..." -ForegroundColor Yellow
    $body = @{ model=$model; max_tokens=8096; system=@(@{ type="text"; text=$SystemPrompt }); messages=@(@{ role="user"; content=$UserMessage }) } | ConvertTo-Json -Depth 6
    try {
        $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($body)
        $r = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $bodyBytes -TimeoutSec 300
        $text = $r.content[0].text
        Write-Host "$(Get-Date -Format 'HH:mm:ss') $Label done ($($text.Length) chars)" -ForegroundColor Green
        return $text
    } catch {
        $sc = $_.Exception.Response.StatusCode.value__
        try { $rd = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream()); $eb = $rd.ReadToEnd() } catch { $eb = $_.Exception.Message }
        Write-Host "$(Get-Date -Format 'HH:mm:ss') ERROR $Label : HTTP $sc | $eb" -ForegroundColor Red
        Write-Status $Label "ERROR: HTTP $sc - $eb" "error" $outputs
        exit 1
    }
}

# STEP 1: Investigation Agent
Write-Status "investigation" "Running Investigation Agent..." "running" $outputs
$invOutput = Invoke-Agent $invPrompt "INCIDENT REPORT:`n`n$incidentContent" "Investigation Agent"
$invFM = ("---", "created: $dateStr", "type: investigation", "source-incident: $fileName", "status: pending-review", "tier: [TO BE CONFIRMED]", "classification: [TO BE CONFIRMED]", "---", "") -join "`n"
[System.IO.File]::WriteAllText($invOutPath, $invFM + "`n" + $invOutput, [System.Text.Encoding]::UTF8)
Write-Host "$(Get-Date -Format 'HH:mm:ss') Written: $invOutPath" -ForegroundColor Green
$outputs["investigation"] = $invOutPath
Write-Status "compliance" "Investigation done. Running Compliance Agent..." "running" $outputs

# STEP 2: Compliance Agent
$compInput  = "ORIGINAL INCIDENT:`n`n$incidentContent`n`n---`n`nINVESTIGATION OUTPUT:`n`n$invOutput"
$compOutput = Invoke-Agent $compPrompt $compInput "Compliance Agent"
$compFM = ("---", "created: $dateStr", "type: compliance-assessment", "source-incident: $fileName", "status: pending-review", "notification-decision: [PENDING GATE 1]", "---", "") -join "`n"
[System.IO.File]::WriteAllText($compOutPath, $compFM + "`n" + $compOutput, [System.Text.Encoding]::UTF8)
Write-Host "$(Get-Date -Format 'HH:mm:ss') Written: $compOutPath" -ForegroundColor Green
$outputs["compliance"] = $compOutPath

# STEP 3: Archive
$archiveDir = Split-Path $archivePath -Parent
if (-not (Test-Path $archiveDir)) { New-Item -ItemType Directory -Path $archiveDir -Force | Out-Null }
Move-Item -Path $FilePath -Destination $archivePath -Force
Write-Host "$(Get-Date -Format 'HH:mm:ss') Archived: $archivePath" -ForegroundColor Green
$outputs["archived"] = $archivePath

# STEP 4: Safety Case Trigger Check
$mapProperties = @("WETNWILD", "MWORLD", "SEAWORLD", "PARADISE", "STUDIOS", "AOS")
$isMAP     = $mapProperties -contains $property
$adiSignal = ($compOutput -imatch "ADI|608B|attributable dangerous|s 608Z|Chapter 9A|safety case")
if ($isMAP -and $adiSignal) {
    Write-Host "$(Get-Date -Format 'HH:mm:ss') ADI signal on MAP property - firing safety case check..." -ForegroundColor Magenta
    $scOutPath = "$vaultRoot\00-Inbox\$dateStr-SAFETYCASE-$dateStr-COMPLIANCE-$fileName.md"
    $outputs["safetyCase"] = $scOutPath
    Write-Status "safetyCase" "ADI detected - running Safety Case Trigger check..." "running" $outputs
    $scScript = "$vaultRoot\12-AgentOutputs\n8n-workflows\run-safety-case-check.ps1"
    & powershell -ExecutionPolicy Bypass -File $scScript -ComplianceFilePath $compOutPath
} else {
    if (-not $isMAP) { Write-Host "$(Get-Date -Format 'HH:mm:ss') Not MAP property - safety case skipped." -ForegroundColor Gray }
    else { Write-Host "$(Get-Date -Format 'HH:mm:ss') No ADI signal - safety case skipped." -ForegroundColor Gray }
}

Write-Status "complete" "Pipeline complete." "complete" $outputs
Write-Host "$(Get-Date -Format 'HH:mm:ss') Pipeline complete." -ForegroundColor Cyan
