$body = @{
    email = "gaddamdeekshitha1@gmail.com"
    password = "Deekshu@15"
} | ConvertTo-Json

$loginRes = Invoke-RestMethod -Uri "http://localhost:8080/api/auth/login" -Method Post -ContentType "application/json" -Body $body
$token = $loginRes.token
$headers = @{
    Authorization = "Bearer $token"
}

$tasks = Invoke-RestMethod -Uri "http://localhost:8080/api/task-live" -Method Get -ContentType "application/json" -Headers $headers
Write-Host "Count: $($tasks.Count)"
if ($tasks.Count -gt 0) {
    $tasks[0] | ConvertTo-Json -Depth 5
}
