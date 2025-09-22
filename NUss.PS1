# Script to disable PowerShell operational logging
# Must be run as Administrator

# Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Please run this script as Administrator!"
    break
}

Write-Host "PowerShell operational logging..." -ForegroundColor Yellow

# Define the logs to disable
$logs = @(
    "Windows PowerShell",
    "Microsoft-Windows-PowerShell/Operational",
    "Microsoft-Windows-PowerShell/Admin"
)

# Method 1: Try using the EventLogConfiguration class
foreach ($log in $logs) {
    try {
        $logConfig = New-Object System.Diagnostics.Eventing.Reader.EventLogConfiguration($log)
        
        if ($logConfig.IsEnabled) {
            $logConfig.IsEnabled = $false
            $logConfig.SaveChanges()
            Write-Host "Successfully disabled $log using .NET method" -ForegroundColor Green
        } else {
            Write-Host "$log is already disabled" -ForegroundColor Yellow
        }
    } catch {
        Write-Host ".NET method failed for $log`: $_" -ForegroundColor Red
    }
}

# Method 2: Try using the wevtutil command with full path
foreach ($log in $logs) {
    try {
        $wevtutilPath = Join-Path $env:SystemRoot "System32\wevtutil.exe"
        if (Test-Path $wevtutilPath) {
            & $wevtutilPath sl $log /e:false
            Write-Host "Successfully disabled $log using wevtutil" -ForegroundColor Green
        } else {
            Write-Host "wevtutil.exe not found at $wevtutilPath" -ForegroundColor Red
        }
    } catch {
        Write-Host "wevtutil method failed for $log`: $_" -ForegroundColor Red
    }
}

# Method 3: Try using the registry approach
foreach ($log in $logs) {
    try {
        $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\EventLog\$log"
        if (-not (Test-Path $registryPath)) {
            New-Item -Path $registryPath -Force | Out-Null
        }
        
        # Set the registry value to disable the log
        New-ItemProperty -Path $registryPath -Name "Enabled" -Value 0 -PropertyType DWORD -Force | Out-Null
        Write-Host "Registry modification successful for $log" -ForegroundColor Green
    } catch {
        Write-Host "Registry modification failed for $log`: $_" -ForegroundColor Red
    }
}

# Verify the changes
Write-Host "`nVerifying changes..." -ForegroundColor Yellow
Get-WinEvent -ListLog $logs | Format-Table LogName, IsEnabled -AutoSize

Write-Host "`nNote: If any logs are still enabled, a system restart may be required for changes to take effect." -ForegroundColor Yellow
