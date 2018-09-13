$frx = Join-Path $env:ProgramFiles 'FSLogix\Apps\frx.exe'

$params = "create-vhd -filename $(Join-Path $env:TEMP test.vhdx)"

Start-Process -FilePath $frx -ArgumentList $params