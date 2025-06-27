# Fix for 32-bit browsers on 64-bit systems
if ($env:PROCESSOR_ARCHITEW6432 -eq "AMD64") {
    if (Test-Path "$env:WINDIR\sysnative\WindowsPowerShell\v1.0\powershell.exe") {
        & "$env:WINDIR\sysnative\WindowsPowerShell\v1.0\powershell.exe" -File $PSCommandPath
        exit
    }
}

# Use the script's directory for logs
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$logPath = Join-Path $scriptDir "native_host.log"

# Ensure directory exists
$dir = $scriptDir
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force }

# Add startup log
"===== Starting native host at $(Get-Date) =====" | Out-File $logPath -Append
"Process ID: $PID" | Out-File $logPath -Append
"Parent Process: $((Get-Process -Id $PID).Parent.Id)" | Out-File $logPath -Append
"Command Line: $($MyInvocation.Line)" | Out-File $logPath -Append

function Read-NativeMessage {
    try {
        $stdin = [System.Console]::OpenStandardInput()
        $lengthBytes = New-Object byte[] 4
        $bytesRead = $stdin.Read($lengthBytes, 0, 4)
        if ($bytesRead -ne 4) { 
            "Failed to read length bytes (read $bytesRead/4)" | Out-File $logPath -Append
            return $null 
        }
        $length = [BitConverter]::ToInt32($lengthBytes, 0)
        if ($length -eq 0) { 
            "Zero-length message received" | Out-File $logPath -Append
            return $null 
        }
        $buffer = New-Object byte[] $length
        $bytesRead = $stdin.Read($buffer, 0, $length)
        if ($bytesRead -ne $length) { 
            "Incomplete message (read $bytesRead/$length bytes)" | Out-File $logPath -Append
            return $null 
        }
        $message = [System.Text.Encoding]::UTF8.GetString($buffer)
        "Received raw message: $message" | Out-File $logPath -Append
        return $message
    }
    catch {
        "Read-NativeMessage error: $_" | Out-File $logPath -Append
        return $null
    }
}

function Write-NativeMessage($message) {
    try {
        "Sending response: $message" | Out-File $logPath -Append
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($message)
        $length = [BitConverter]::GetBytes($bytes.Length)
        $stdout = [System.Console]::OpenStandardOutput()
        $stdout.Write($length, 0, 4)
        $stdout.Write($bytes, 0, $bytes.Length)
        $stdout.Flush()
    }
    catch {
        "Write-NativeMessage error: $_" | Out-File $logPath -Append
    }
}

try {
    # Main loop
    while ($true) {
        $message = Read-NativeMessage
        if (-not $message) { 
            "No valid input received, exiting" | Out-File $logPath -Append
            break 
        }
        
        "Received: $message" | Out-File $logPath -Append
        
        try {
            $data = $message | ConvertFrom-Json -ErrorAction Stop
        }
        catch {
            "JSON Parse Error: $_" | Out-File $logPath -Append
            Write-NativeMessage ('{"error":"Invalid JSON format"}')
            continue
        }
        
        if ($data.url) {
            $decodedUrl = [System.Uri]::UnescapeDataString($data.url)
            "Decoded URL: $decodedUrl" | Out-File $logPath -Append
            
            $potPath = "C:\Program Files\DAUM\PotPlayer\PotPlayerMini64.exe"
            if (-not (Test-Path $potPath)) {
                $potPath = "C:\Program Files (x86)\DAUM\PotPlayer\PotPlayerMini.exe"
            }
            
            if (Test-Path $potPath) {
                $arguments = "`"$decodedUrl`""
                Start-Process -FilePath $potPath -ArgumentList $arguments
                "Launched PotPlayer with: $arguments" | Out-File $logPath -Append
                Write-NativeMessage ('{"success": true}')
            } else {
                throw "PotPlayer not found at $potPath"
            }
        }
        elseif ($data.test -eq "ping") {
            "Received ping test" | Out-File $logPath -Append
            Write-NativeMessage ('{"response": "pong"}')
        }
        else {
            throw "Invalid message format"
        }
    }
}
catch {
    $errMsg = "ERROR: $($_.Exception.Message)"
    $errMsg | Out-File $logPath -Append
    Write-NativeMessage ('{"error": "' + $errMsg + '"}')
}

# Add shutdown log
"===== Exiting native host at $(Get-Date) =====" | Out-File $logPath -Append