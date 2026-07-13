function Test-Dashboard($email, $password) {
    Write-Host "Testing for $email..."
    $body = @{
        email = $email
        password = $password
    } | ConvertTo-Json

    try {
        $loginRes = Invoke-RestMethod -Uri "http://localhost:8080/api/auth/login" -Method Post -ContentType "application/json" -Body $body
        Write-Host "Login successful: success=$($loginRes.success), role=$($loginRes.role)"
        
        $token = $loginRes.token
        $headers = @{
            Authorization = "Bearer $token"
        }
        
        $dashRes = Invoke-RestMethod -Uri "http://localhost:8080/api/user-dashboard" -Method Get -ContentType "application/json" -Headers $headers
        Write-Host "Dashboard retrieval: SUCCESS!"
        Write-Host "Response JSON:"
        $dashRes | ConvertTo-Json -Depth 10
    } catch {
        Write-Error $_
        if ($_.Exception.Response) {
            $stream = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($stream)
            $responseBody = $reader.ReadToEnd()
            Write-Host "Error Response Body: $responseBody"
        }
    }
}

Write-Host "--- ADMIN DASHBOARD TEST ---"
Test-Dashboard "vkpraveen216@gmail.com" "Kumar@2311"

Write-Host "`n--- USER DASHBOARD TEST ---"
Test-Dashboard "gaddamdeekshitha1@gmail.com" "Deekshu@15"
