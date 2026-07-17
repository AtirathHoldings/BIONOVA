$loginBody = @{ email = "vkpraveen216@gmail.com"; password = "Kumar@2311" } | ConvertTo-Json
$loginResp = Invoke-RestMethod -Uri "http://localhost:8080/api/auth/login" -Method POST -Body $loginBody -ContentType "application/json"
$token = $loginResp.token
$headers = @{ "Authorization" = "Bearer $token" }

Write-Host "=== PROJECTS LIST ===" -ForegroundColor Cyan
$projects = Invoke-RestMethod -Uri "http://localhost:8080/api/project-live" -Headers $headers
foreach ($p in $projects) {
    Write-Host "  PRJ-$($p.prjId) | $($p.prjNm) | Status: $($p.prjSts) | Start: $($p.stDt) | End: $($p.endDt)"
}

Write-Host "`n=== GANTT DATA PER PROJECT ===" -ForegroundColor Cyan
$uniqueIds = $projects | Select-Object -Property prjId -Unique
foreach ($p in $uniqueIds) {
    Write-Host "`n--- Project ID: $($p.prjId) ---" -ForegroundColor Yellow
    try {
        $gantt = Invoke-RestMethod -Uri "http://localhost:8080/api/gantt/$($p.prjId)" -Headers $headers
        foreach ($item in $gantt) {
            $indent = ""
            if ($item.type -eq "milestone") { $indent = "  " }
            if ($item.type -eq "task") { $indent = "    " }
            $prog = [math]::Round($item.progress * 100)
            Write-Host "$indent[$($item.type.ToUpper())] $($item.id) | $($item.name) | Status: $($item.status) | Progress: ${prog}% | Start: $($item.startDate) | End: $($item.endDate) | Parent: $($item.parent) | Assignee: $($item.assignee) | Baseline: $($item.plannedStartDate)-$($item.plannedEndDate)"
        }
    } catch {
        Write-Host "  ERROR: $($_.Exception.Message)" -ForegroundColor Red
    }
}
