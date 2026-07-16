$body = @{
    email = "vkpraveen216@gmail.com"
    password = "Kumar@2311"
} | ConvertTo-Json

$loginRes = Invoke-RestMethod -Uri "http://localhost:8080/api/auth/login" -Method Post -ContentType "application/json" -Body $body
$token = $loginRes.token
$headers = @{
    Authorization = "Bearer $token"
}

$employees = Invoke-RestMethod -Uri "http://localhost:8080/api/employees" -Method Get -ContentType "application/json" -Headers $headers
$employees | ConvertTo-Json -Depth 5
