function Get-WriteLog {
    # --- Set the uri for the latest release
    $URI = "https://api.github.com/repos/JimMoyle/YetAnotherWriteLog/releases/latest"

    [Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"

    # --- Query the API to get the url of the zip
    $response = Invoke-RestMethod -Method Get -Uri $URI
    $zipUrl = $Response.zipball_url

    # --- Download the file to the current location
    $OutputPath = "$((Get-Location).Path)\$($Response.name.Replace(" ","_")).zip"
    Invoke-RestMethod -Method Get -Uri $ZipUrl -OutFile $OutputPath

    Expand-Archive -Path $OutputPath -DestinationPath $env:TEMP\zip\ -Force

    $writeLog = Get-ChildItem $env:TEMP\zip\ -Recurse -Include write-log.ps1 | Get-Content

    Write-Output $writeLog

    Remove-Item $OutputPath
    Remove-Item $env:TEMP\zip -Force -Recurse
}

function Add-FslReleaseFunction {
    [cmdletbinding()]
    param (
        [Parameter(
            Position = 0,
            ValuefromPipelineByPropertyName = $true,
            Mandatory = $false
        )]
        [System.String]$FunctionsFolder = '.\Functions',

        [Parameter(
            Position = 1,
            ValuefromPipelineByPropertyName = $true,
            Mandatory = $false
        )]
        [System.String]$ReleaseFolder = '.\Release',
        [Parameter(
            Position = 1,
            ValuefromPipelineByPropertyName = $true,
            Mandatory = $true
        )]
        [System.String]$ControlScript
    )

    $ctrlScript = Get-Content -Path (Join-Path $FunctionsFolder $ControlScript)

    if ($ctrlScript -match '#Write-Log') {
        $logger = Get-WriteLog
        $logger | Set-Content (Join-Path $FunctionsFolder Write-Log.ps1)
    }

    $funcs = Get-ChildItem $FunctionsFolder -File | Where-Object {$_.Name -ne $ControlScript}

    foreach ($funcName in $funcs) {

        $pattern = "#$($funcName.BaseName)"
        $actualFunc = Get-Content (Join-Path $FunctionsFolder $funcName)

        $ctrlScript = $ctrlScript | Foreach-Object {
            $_
            if ($_ -match $pattern ) {
                $actualFunc
            }
        }
    }
    $ctrlScript | Set-Content (Join-Path $ReleaseFolder $ControlScript)
}

Add-FslRelease -ControlScript 'Rename-Disk.ps1'