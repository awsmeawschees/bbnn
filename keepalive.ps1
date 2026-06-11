$wshell = New-Object -ComObject WScript.Shell
while($true) {
    $wshell.SendKeys('{SCROLLLOCK}')
    Start-Sleep -Seconds 240
}
