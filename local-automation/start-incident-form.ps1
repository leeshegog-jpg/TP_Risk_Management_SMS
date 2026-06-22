$inboxPath  = "D:\LeeShe_Obsidian_Vault\LeeShe_Obsidian_Vault\00-Inbox"
$statusDir  = "D:\LeeShe_Obsidian_Vault\LeeShe_Obsidian_Vault\12-AgentOutputs\n8n-workflows\pipeline-status"
$vaultName  = "LeeShe_Obsidian_Vault"
$port       = 8765
$url        = "http://localhost:$port/"

$html = @'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>VRTP Incident Report</title>
<style>
* { box-sizing: border-box; margin: 0; padding: 0; }
body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; background: #0f1117; color: #e2e8f0; min-height: 100vh; padding: 2rem; }
.container { max-width: 860px; margin: 0 auto; }
header { display: flex; align-items: center; gap: 1rem; margin-bottom: 2rem; padding-bottom: 1rem; border-bottom: 1px solid #2d3748; }
header h1 { font-size: 1.4rem; font-weight: 700; color: #f7fafc; }
header span { font-size: 0.85rem; color: #718096; }
.badge { background: #c53030; color: #fff; font-size: 0.7rem; font-weight: 700; padding: 2px 8px; border-radius: 4px; letter-spacing: 0.05em; }
.card { background: #1a202c; border: 1px solid #2d3748; border-radius: 8px; padding: 1.5rem; margin-bottom: 1.5rem; }
.card h2 { font-size: 0.8rem; font-weight: 700; text-transform: uppercase; letter-spacing: 0.08em; color: #718096; margin-bottom: 1rem; }
.grid-2 { display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; }
.grid-3 { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 1rem; }
label { display: block; font-size: 0.8rem; font-weight: 600; color: #a0aec0; margin-bottom: 0.3rem; }
label .req { color: #fc8181; margin-left: 2px; }
input, select, textarea { width: 100%; background: #2d3748; border: 1px solid #4a5568; border-radius: 5px; color: #e2e8f0; padding: 0.55rem 0.75rem; font-size: 0.9rem; font-family: inherit; transition: border-color 0.15s; }
input:focus, select:focus, textarea:focus { outline: none; border-color: #63b3ed; }
select option { background: #2d3748; }
textarea { resize: vertical; min-height: 100px; line-height: 1.5; }
.hint { font-size: 0.73rem; color: #4a5568; margin-top: 0.25rem; }
.severity-row { display: flex; gap: 0.5rem; flex-wrap: wrap; }
.sev-btn { flex: 1; min-width: 80px; padding: 0.5rem; border: 2px solid #4a5568; border-radius: 5px; background: transparent; color: #a0aec0; font-size: 0.78rem; font-weight: 700; cursor: pointer; text-align: center; transition: all 0.15s; }
.sev-btn.active-fa  { border-color: #68d391; background: #1c4532; color: #68d391; }
.sev-btn.active-mti { border-color: #f6e05e; background: #44370a; color: #f6e05e; }
.sev-btn.active-lti { border-color: #f6ad55; background: #44270a; color: #f6ad55; }
.sev-btn.active-si  { border-color: #fc8181; background: #4a1010; color: #fc8181; }
.sev-btn.active-di  { border-color: #e53e3e; background: #4a0000; color: #e53e3e; }
.sev-btn.active-nm  { border-color: #63b3ed; background: #0a2040; color: #63b3ed; }
.actions { display: flex; gap: 1rem; align-items: center; justify-content: flex-end; padding-top: 1rem; border-top: 1px solid #2d3748; }
.btn-reset  { background: transparent; border: 1px solid #4a5568; color: #718096; padding: 0.6rem 1.4rem; border-radius: 5px; cursor: pointer; font-size: 0.85rem; }
.btn-reset:hover { border-color: #718096; color: #a0aec0; }
.btn-submit { background: #c53030; border: none; color: #fff; padding: 0.65rem 2rem; border-radius: 5px; cursor: pointer; font-size: 0.9rem; font-weight: 700; }
.btn-submit:hover { background: #9b2c2c; }
.btn-submit:disabled { background: #4a5568; cursor: not-allowed; }
/* Pipeline status panel */
#pipelinePanel { display: none; }
.pipeline-card { background: #1a202c; border: 1px solid #2d3748; border-radius: 8px; padding: 1.5rem; margin-bottom: 1.5rem; }
.pipeline-title { font-size: 1rem; font-weight: 700; margin-bottom: 1.2rem; color: #f7fafc; }
.step-list { list-style: none; }
.step-list li { display: flex; align-items: center; gap: 0.75rem; padding: 0.6rem 0; border-bottom: 1px solid #2d3748; font-size: 0.88rem; }
.step-list li:last-child { border-bottom: none; }
.step-icon { width: 22px; text-align: center; font-size: 1rem; flex-shrink: 0; }
.step-label { flex: 1; color: #a0aec0; }
.step-label.active { color: #f7fafc; }
.step-label.done   { color: #68d391; }
.step-label.error  { color: #fc8181; }
.spinner { display: inline-block; width: 14px; height: 14px; border: 2px solid #4a5568; border-top-color: #63b3ed; border-radius: 50%; animation: spin 0.7s linear infinite; }
@keyframes spin { to { transform: rotate(360deg); } }
.results-grid { display: grid; gap: 0.75rem; margin-top: 1rem; }
.result-item { background: #2d3748; border-radius: 6px; padding: 1rem; display: flex; align-items: center; justify-content: space-between; gap: 1rem; }
.result-label { font-size: 0.82rem; font-weight: 700; color: #a0aec0; text-transform: uppercase; letter-spacing: 0.05em; }
.result-name { font-size: 0.85rem; color: #e2e8f0; margin-top: 0.15rem; word-break: break-all; }
.btn-open { background: #2b4c7e; border: none; color: #90cdf4; padding: 0.4rem 1rem; border-radius: 4px; cursor: pointer; font-size: 0.8rem; font-weight: 600; white-space: nowrap; text-decoration: none; display: inline-block; }
.btn-open:hover { background: #2c5282; }
.result-actions { display: flex; gap: 0.5rem; flex-shrink: 0; flex-wrap: wrap; justify-content: flex-end; }
.btn-pdf { background: #c53030; border: none; color: #fff; padding: 0.65rem 2rem; border-radius: 5px; cursor: pointer; font-size: 0.9rem; font-weight: 700; text-decoration: none; display: inline-block; margin-top: 1rem; width: 100%; text-align: center; }
.btn-pdf:hover { background: #9b2c2c; }
.alert-error { background: #4a1010; border: 1px solid #fc8181; color: #fc8181; padding: 1rem; border-radius: 6px; font-size: 0.88rem; margin-top: 0.75rem; }
.alert-success { background: #1c4532; border: 1px solid #68d391; color: #68d391; padding: 1rem; border-radius: 6px; font-size: 0.9rem; font-weight: 600; margin-top: 0.75rem; text-align: center; }
.btn-new { background: #c53030; border: none; color: #fff; padding: 0.65rem 2rem; border-radius: 5px; cursor: pointer; font-size: 0.9rem; font-weight: 700; width: 100%; margin-top: 1rem; }
.btn-new:hover { background: #9b2c2c; }
</style>
</head>
<body>
<div class="container">
  <header>
    <div class="badge">SAFETY</div>
    <div>
      <h1>VRTP Incident Report</h1>
      <span>Submitting this form starts the automated investigation pipeline</span>
    </div>
  </header>

  <!-- FORM -->
  <div id="formSection">
    <form id="incidentForm">
      <div class="card">
        <h2>Incident Details</h2>
        <div class="grid-3">
          <div>
            <label>Property <span class="req">*</span></label>
            <select name="property" required>
              <option value="">Select...</option>
              <option value="WnW">Wet n Wild Gold Coast</option>
              <option value="MovieWorld">Movie World</option>
              <option value="SeaWorld">Sea World</option>
              <option value="SkyPoint">SkyPoint</option>
              <option value="Studios">Warner Bros. Studios</option>
              <option value="Paradise">Paradise Country</option>
              <option value="AOS">Australian Outback Spectacular</option>
              <option value="TopGolf">TopGolf</option>
              <option value="Resort">Village Roadshow Resort</option>
            </select>
          </div>
          <div>
            <label>Date of Incident <span class="req">*</span></label>
            <input type="date" name="incident_date" required>
          </div>
          <div>
            <label>Time of Incident <span class="req">*</span></label>
            <input type="time" name="incident_time" required>
          </div>
        </div>
        <div style="margin-top:1rem">
          <label>Location / Area <span class="req">*</span></label>
          <input type="text" name="location" placeholder="e.g. Wave Pool shallow end, Main Street near entrance" required>
        </div>
      </div>

      <div class="card">
        <h2>Classification</h2>
        <label style="margin-bottom:0.5rem">Incident Severity <span class="req">*</span></label>
        <div class="severity-row">
          <button type="button" class="sev-btn" data-value="First Aid" data-cls="active-fa">First Aid</button>
          <button type="button" class="sev-btn" data-value="Medical Treatment Injury" data-cls="active-mti">MTI</button>
          <button type="button" class="sev-btn" data-value="Lost Time Injury" data-cls="active-lti">LTI</button>
          <button type="button" class="sev-btn" data-value="Serious Injury" data-cls="active-si">Serious Injury</button>
          <button type="button" class="sev-btn" data-value="Dangerous Incident" data-cls="active-di">Dangerous Incident</button>
          <button type="button" class="sev-btn" data-value="Near Miss" data-cls="active-nm">Near Miss</button>
        </div>
        <input type="hidden" name="severity" id="severityValue">
        <p class="hint">MTI = Medical Treatment Injury. LTI = Lost Time Injury.</p>
        <div style="margin-top:1rem">
          <label>Ride / Attraction / Area Involved</label>
          <input type="text" name="ride_asset" placeholder="e.g. Tornado ride (Asset ID: WNW-042), Wave Pool">
        </div>
      </div>

      <div class="card">
        <h2>People Involved</h2>
        <div class="grid-2">
          <div>
            <label>Injured / Affected Person</label>
            <input type="text" name="person_type" placeholder="e.g. Guest, adult male approx 35">
          </div>
          <div>
            <label>Nature of Injury</label>
            <input type="text" name="injury_type" placeholder="e.g. Unresponsive in water, suspected cervical injury">
          </div>
        </div>
        <div style="margin-top:1rem">
          <label>Staff on Duty</label>
          <input type="text" name="staff_present" placeholder="e.g. 2 lifeguards, 1 duty manager">
        </div>
        <div style="margin-top:1rem">
          <label>Current Status of Affected Person</label>
          <input type="text" name="person_status" placeholder="e.g. Transported to GCUH, ICU admission">
        </div>
      </div>

      <div class="card">
        <h2>What Happened <span class="req">*</span></h2>
        <textarea name="narrative" rows="6" placeholder="Describe sequence of events. Include: what was happening before, what occurred, what was noticed and when, immediate response." required></textarea>
      </div>

      <div class="card">
        <h2>Immediate Actions Taken</h2>
        <textarea name="immediate_actions" rows="4" placeholder="e.g. Lifeguard entered water at 14:34, CPR commenced, ambulance called 14:35, area shut down, CCTV secured."></textarea>
      </div>

      <div class="card">
        <h2>Notifications</h2>
        <div class="grid-2">
          <div>
            <label>WHSQ notified?</label>
            <select name="whsq_notified">
              <option value="Not yet assessed">Not yet assessed</option>
              <option value="Yes">Yes</option>
              <option value="No - assessed not required">No - assessed not required</option>
              <option value="No - under assessment">No - under assessment</option>
            </select>
          </div>
          <div>
            <label>OSR (Chapter 9A) notified?</label>
            <select name="osr_notified">
              <option value="Not applicable / under assessment">Not applicable / under assessment</option>
              <option value="Yes">Yes</option>
              <option value="No - assessed not required">No - assessed not required</option>
              <option value="No - under assessment">No - under assessment</option>
            </select>
          </div>
        </div>
        <div style="margin-top:1rem">
          <label>Additional Notes</label>
          <textarea name="other_notes" rows="3" placeholder="Witness names, CCTV coverage, equipment status, weather, patron count, etc."></textarea>
        </div>
      </div>

      <div class="card">
        <h2>Reported By</h2>
        <div class="grid-2">
          <div>
            <label>Your Name <span class="req">*</span></label>
            <input type="text" name="reporter_name" required placeholder="Full name">
          </div>
          <div>
            <label>Your Role</label>
            <input type="text" name="reporter_role" placeholder="e.g. Duty Manager, Safety Officer">
          </div>
        </div>
      </div>

      <div class="actions">
        <button type="button" class="btn-reset" onclick="resetForm()">Clear Form</button>
        <button type="submit" class="btn-submit" id="submitBtn">Submit and Start Pipeline</button>
      </div>
    </form>
  </div>

  <!-- PIPELINE STATUS PANEL -->
  <div id="pipelinePanel">
    <div class="pipeline-card">
      <div class="pipeline-title" id="panelTitle">Pipeline Running...</div>
      <ul class="step-list" id="stepList">
        <li id="step-start">    <span class="step-icon" id="icon-start">&#x23F3;</span><span class="step-label" id="lbl-start">Incident file created</span></li>
        <li id="step-investigation"><span class="step-icon" id="icon-investigation">&#x25CB;</span><span class="step-label" id="lbl-investigation">Investigation Agent</span></li>
        <li id="step-compliance">  <span class="step-icon" id="icon-compliance">&#x25CB;</span><span class="step-label" id="lbl-compliance">Compliance Agent</span></li>
        <li id="step-archive">     <span class="step-icon" id="icon-archive">&#x25CB;</span><span class="step-label" id="lbl-archive">Archiving source file</span></li>
        <li id="step-safetyCase">  <span class="step-icon" id="icon-safetyCase">&#x25CB;</span><span class="step-label" id="lbl-safetyCase">Safety Case Trigger Check</span></li>
        <li id="step-complete">    <span class="step-icon" id="icon-complete">&#x25CB;</span><span class="step-label" id="lbl-complete">Complete</span></li>
      </ul>
      <div id="resultsSection" style="display:none">
        <div class="alert-success" id="successMsg">Pipeline complete. Review outputs below.</div>
        <div class="results-grid" id="resultsGrid"></div>
        <a class="btn-pdf" id="pdfReportBtn" href="#" target="_blank">&#x1F4C4; Download PDF Report</a>
        <button class="btn-new" onclick="newReport()">Submit Another Incident</button>
      </div>
      <div id="errorSection" style="display:none">
        <div class="alert-error" id="errorMsg">An error occurred.</div>
        <button class="btn-new" onclick="newReport()">Try Again</button>
      </div>
    </div>
  </div>

</div>

<script>
const VAULT = 'LeeShe_Obsidian_Vault';
let pollInterval = null;
let currentJob   = null;

// Severity buttons
document.querySelectorAll('.sev-btn').forEach(btn => {
  btn.addEventListener('click', () => {
    document.querySelectorAll('.sev-btn').forEach(b => b.className = 'sev-btn');
    btn.classList.add(btn.dataset.cls);
    document.getElementById('severityValue').value = btn.dataset.value;
  });
});

document.querySelector('[name=incident_date]').value = new Date().toISOString().split('T')[0];

function resetForm() {
  document.getElementById('incidentForm').reset();
  document.querySelectorAll('.sev-btn').forEach(b => b.className = 'sev-btn');
  document.getElementById('severityValue').value = '';
  document.getElementById('submitBtn').disabled = false;
  document.getElementById('submitBtn').textContent = 'Submit and Start Pipeline';
  document.querySelector('[name=incident_date]').value = new Date().toISOString().split('T')[0];
}

function newReport() {
  clearInterval(pollInterval);
  document.getElementById('pipelinePanel').style.display = 'none';
  document.getElementById('formSection').style.display = 'block';
  resetForm();
  resetSteps();
}

function resetSteps() {
  ['start','investigation','compliance','archive','safetyCase','complete'].forEach(s => {
    document.getElementById('icon-'+s).innerHTML = '&#x25CB;';
    document.getElementById('lbl-'+s).className = 'step-label';
  });
  document.getElementById('resultsSection').style.display = 'none';
  document.getElementById('errorSection').style.display   = 'none';
}

function obsidianUrl(filePath) {
  // Convert Windows path to Obsidian vault-relative path
  const vaultRoot = filePath.indexOf('LeeShe_Obsidian_Vault\\LeeShe_Obsidian_Vault\\');
  if (vaultRoot === -1) return null;
  const rel = filePath.substring(vaultRoot + 'LeeShe_Obsidian_Vault\\LeeShe_Obsidian_Vault\\'.length)
                      .replace(/\\/g, '/');
  return 'obsidian://open?vault=' + encodeURIComponent(VAULT) + '&file=' + encodeURIComponent(rel);
}

function setStep(id, state, label) {
  const icon = document.getElementById('icon-'+id);
  const lbl  = document.getElementById('lbl-'+id);
  if (label) lbl.textContent = label;
  if (state === 'active') {
    icon.innerHTML = '<span class="spinner"></span>';
    lbl.className = 'step-label active';
  } else if (state === 'done') {
    icon.textContent = '✓';
    lbl.className = 'step-label done';
  } else if (state === 'error') {
    icon.textContent = '✗';
    lbl.className = 'step-label error';
  } else if (state === 'skip') {
    icon.textContent = '—';
    lbl.className = 'step-label';
  }
}

function renderResults(outputs) {
  const grid = document.getElementById('resultsGrid');
  grid.innerHTML = '';
  const items = [
    { key: 'investigation', label: 'Investigation Report' },
    { key: 'compliance',    label: 'Compliance Assessment' },
    { key: 'safetyCase',    label: 'Safety Case Trigger' },
    { key: 'archived',      label: 'Archived Source' }
  ];
  items.forEach(item => {
    const path = outputs[item.key];
    if (!path) return;
    const name = path.split('\\').pop();
    const oUrl = obsidianUrl(path);
    const div = document.createElement('div');
    div.className = 'result-item';
    div.innerHTML =
      '<div><div class="result-label">' + item.label + '</div><div class="result-name">' + name + '</div></div>' +
      '<div class="result-actions">' +
      (oUrl ? '<a class="btn-open" href="' + oUrl + '">Open in Obsidian</a>' : '') +
      '</div>';
    grid.appendChild(div);
  });
}

function pollStatus(jobId) {
  fetch('/status/' + encodeURIComponent(jobId))
    .then(r => r.json())
    .then(data => {
      const step = data.step || '';
      const state = data.status;

      // Update steps based on current step
      if (step === 'starting') {
        setStep('start', 'done');
        setStep('investigation', 'active', 'Investigation Agent running...');
      }
      if (step === 'investigation' || step === 'compliance' || step === 'archive' || step === 'safetyCase' || step === 'complete') {
        setStep('start', 'done');
      }
      if (step === 'compliance') {
        setStep('investigation', 'done', 'Investigation Agent');
        setStep('compliance', 'active', 'Compliance Agent running...');
      }
      if (step === 'archive' || step === 'safetyCase' || step === 'complete') {
        setStep('investigation', 'done', 'Investigation Agent');
        setStep('compliance', 'done', 'Compliance Agent');
        setStep('archive', 'done', 'Source archived');
      }
      if (step === 'safetyCase') {
        setStep('safetyCase', 'active', 'Safety Case Trigger check running...');
      }
      if (step === 'complete') {
        const hasSC = data.outputs && data.outputs.safetyCase && data.outputs.safetyCase !== '';
        setStep('safetyCase', hasSC ? 'done' : 'skip', hasSC ? 'Safety Case Trigger check' : 'Safety Case check (not required)');
        setStep('complete', 'done', 'Pipeline complete');
        document.getElementById('panelTitle').textContent = 'Pipeline Complete';
        clearInterval(pollInterval);
        renderResults(data.outputs || {});
        document.getElementById('pdfReportBtn').href = '/report/' + encodeURIComponent(currentJob);
        document.getElementById('resultsSection').style.display = 'block';
      }
      if (state === 'error') {
        clearInterval(pollInterval);
        document.getElementById('panelTitle').textContent = 'Pipeline Error';
        document.getElementById('errorMsg').textContent = 'Error at step: ' + step + '. ' + (data.message || '');
        document.getElementById('errorSection').style.display = 'block';
      }
    })
    .catch(() => {}); // ignore poll errors silently
}

document.getElementById('incidentForm').addEventListener('submit', async function(e) {
  e.preventDefault();
  if (!document.getElementById('severityValue').value) {
    alert('Please select an incident severity.');
    return;
  }
  const btn = document.getElementById('submitBtn');
  btn.disabled = true;
  btn.textContent = 'Submitting...';

  const data = {};
  new FormData(this).forEach((v, k) => data[k] = v);

  try {
    const res = await fetch('/submit', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data)
    });
    const result = await res.json();

    if (result.ok) {
      currentJob = result.jobId;
      document.getElementById('formSection').style.display = 'none';
      document.getElementById('pipelinePanel').style.display = 'block';
      resetSteps();
      setStep('start', 'done', 'Incident file created: ' + result.filename);
      setStep('investigation', 'active', 'Investigation Agent running...');
      pollInterval = setInterval(() => pollStatus(currentJob), 5000);
    } else {
      btn.disabled = false;
      btn.textContent = 'Submit and Start Pipeline';
      alert('Error: ' + result.error);
    }
  } catch(err) {
    btn.disabled = false;
    btn.textContent = 'Submit and Start Pipeline';
    alert('Could not connect to local server. Is start-incident-form.ps1 running?');
  }
});
</script>
</body>
</html>
'@

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

        # Serve HTML form
        if ($request.HttpMethod -eq "GET" -and $path -eq "/") {
            $buf = [System.Text.Encoding]::UTF8.GetBytes($html)
            $response.ContentType = "text/html; charset=utf-8"
            $response.ContentLength64 = $buf.Length
            $response.OutputStream.Write($buf, 0, $buf.Length)

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
