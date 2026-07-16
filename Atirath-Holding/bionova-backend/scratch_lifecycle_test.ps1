$body = @{
    email = "vkpraveen216@gmail.com"
    password = "Kumar@2311"
} | ConvertTo-Json

$loginRes = Invoke-RestMethod -Uri "http://localhost:8080/api/auth/login" -Method Post -ContentType "application/json" -Body $body
$token = $loginRes.token
$headers = @{
    Authorization = "Bearer $token"
}

# Task ID to test
$taskId = 19

Write-Host "============================================="
Write-Host "TASK LIFECYCLE SMOKE TEST FOR TASK ID: $taskId"
Write-Host "============================================="

# 1. Fetch current status
Write-Host "1. Fetching current task details..."
$allTasks = Invoke-RestMethod -Uri "http://localhost:8080/api/task-live" -Method Get -Headers $headers
Write-Host "Total tasks fetched: $($allTasks.Count)"
$task = $allTasks | Where-Object { $_.taskId -eq $taskId }
Write-Host "Matched task JSON:"
$task | ConvertTo-Json -Depth 2
Write-Host "Current Task Status: $($task.taskSts) (SubStatus: $($task.subStatus))"

# Reset status if not Open
if ($task.taskSts -ne "Open") {
    Write-Host "Resetting task status to Open via database/endpoint..."
    # We can write to a helper endpoint if needed, or we just try starting it or handle it.
}

# 2. Start Task
Write-Host "`n2. Starting the task (Open -> WIP)..."
try {
    # If the task is already WIP, we might get a bad request, so let's handle or log it
    $startBody = @{ empId = 5 } | ConvertTo-Json
    $startRes = Invoke-RestMethod -Uri "http://localhost:8080/api/process/task/$taskId/start" -Method Post -ContentType "application/json" -Headers $headers -Body $startBody
    Write-Host "Start Response: $($startRes | ConvertTo-Json -Compress)"
} catch {
    Write-Error $_
    if ($_.Exception.Response) {
        $stream = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($stream)
        $responseBody = $reader.ReadToEnd()
        Write-Host "Error details: $responseBody"
    }
}

# 3. Fetch checklist items
Write-Host "`n3. Checking for checklist items..."
$checklists = Invoke-RestMethod -Uri "http://localhost:8080/api/checklists/live-task/$taskId" -Method Get -Headers $headers
Write-Host "Found $($checklists.Count) checklist items."

# Complete checklist items
foreach ($item in $checklists) {
    if (-not $item.chkSts) {
        Write-Host "Completing checklist item: $($item.chkNm) (ID: $($item.chkId))"
        $compRes = Invoke-RestMethod -Uri "http://localhost:8080/api/checklists/$($item.chkId)/complete" -Method Patch -Headers $headers
        Write-Host "Completed: $($compRes | ConvertTo-Json -Compress)"
    }
}

# 4. Submit Task for Review
Write-Host "`n4. Submitting task for review..."
try {
    $submitBody = @{
        empId = 5
        remarks = "Smoke test submission"
    } | ConvertTo-Json
    $submitRes = Invoke-RestMethod -Uri "http://localhost:8080/api/process/task/$taskId/submit" -Method Post -ContentType "application/json" -Headers $headers -Body $submitBody
    Write-Host "Submit Response: $($submitRes | ConvertTo-Json -Compress)"
} catch {
    Write-Error $_
    if ($_.Exception.Response) {
        $stream = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($stream)
        $responseBody = $reader.ReadToEnd()
        Write-Host "Error details: $responseBody"
    }
}

# 5. Checker/Reviewer Action (SUBMIT_REVIEW -> UNDER_REVIEW)
Write-Host "`n5. First-level Checker Action (Approval)..."
try {
    $checkerBody = @{
        empId = 8
        decision = "YES"
        remarks = "Checker approved"
    } | ConvertTo-Json
    $checkerRes = Invoke-RestMethod -Uri "http://localhost:8080/api/process/task/$taskId/checker-action" -Method Post -ContentType "application/json" -Headers $headers -Body $checkerBody
    Write-Host "Checker Response: $($checkerRes | ConvertTo-Json -Compress)"
} catch {
    Write-Error $_
    if ($_.Exception.Response) {
        $stream = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($stream)
        $responseBody = $reader.ReadToEnd()
        Write-Host "Error details: $responseBody"
    }
}

# 6. Approver Action (UNDER_REVIEW -> COMPLETED)
Write-Host "`n6. Second-level Approver Action (Approval)..."
try {
    $approverBody = @{
        empId = 7
        decision = "YES"
        remarks = "Approver approved"
    } | ConvertTo-Json
    $approverRes = Invoke-RestMethod -Uri "http://localhost:8080/api/process/task/$taskId/reviewer-action" -Method Post -ContentType "application/json" -Headers $headers -Body $approverBody
    Write-Host "Approver Response: $($approverRes | ConvertTo-Json -Compress)"
} catch {
    Write-Error $_
    if ($_.Exception.Response) {
        $stream = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($stream)
        $responseBody = $reader.ReadToEnd()
        Write-Host "Error details: $responseBody"
    }
}

# 7. Final task status verification
Write-Host "`n7. Verifying final task status..."
$taskFinal = Invoke-RestMethod -Uri "http://localhost:8080/api/task-live" -Method Get -Headers $headers | Where-Object { $_.taskId -eq $taskId }
Write-Host "Final Task Status: $($taskFinal.taskSts) (SubStatus: $($taskFinal.subStatus))"
Write-Host "============================================="
