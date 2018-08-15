#requires -Module 'ActiveDirectory'

function Remove-FslMultiOst {
    [CmdletBinding()]

    Param (
        [Parameter(
            Position = 0,
            ValuefromPipelineByPropertyName = $true,
            ValuefromPipeline = $true,
            Mandatory = $true
        )]
        [System.String]$Path
    )

    BEGIN {
        Set-StrictMode -Version Latest
    } # Begin
    PROCESS {
        #Write-Log  "Getting ost files from $Path"
        $ost = Get-ChildItem -Path (Join-Path $Path *.ost)
        if ($null -eq $ost) {
            #Write-log -level Warn "Did not find any ost files in $Path"
            $ostDelNum = 0
        }
        else {

            $count = $ost | Measure-Object 

            if ($count.Count -gt 1) {

                $mailboxes = $ost.BaseName.trimend('(', ')', '1', '2', '3', '4', '5', '6', '7', '8', '9', '0') | Group-Object | Select-Object -ExpandProperty Name

                foreach ($mailbox in $mailboxes) {
                    $mailboxOst = $ost | Where-Object {$_.BaseName.StartsWith($mailbox)}

                    #So this is weird if only one file is there it doesn't have a count property! Probably better to use measure-object
                    try {
                        $mailboxOst.count | Out-Null
                        $count = $mailboxOst.count
                    }
                    catch {
                        $count = 1
                    }
                    #Write-Log  "Found $count ost files for $mailbox"

                    if ($count -gt 1) {

                        $ostDelNum = $count - 1
                        #Write-Log "Deleting $ostDelNum ost files"
                        try {
                            $latestOst = $mailboxOst | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1
                            $mailboxOst | Where-Object {$_.Name -ne $latestOst.Name} | Remove-Item -Force -ErrorAction Stop
                        }
                        catch {
                            #write-log -level Error "Failed to delete ost files in $vhd for $mailbox"
                        }
                    }
                    else {
                        #Write-Log "Only One ost file found for $mailbox. No action taken"
                        $ostDelNum = 0
                    }

                }
            }
        }
    } #Process
    END {} #End
}  #function Remove-FslMultiOst

# to parmaaterise
$userName = 'jim'
$O365Folder = "\\labdc01\FSLogixContainers\"
$vhdx = $false

if ($vhdx) {
    $extension = '.vhdx'
}
else {
    $extension = '.vhd'
}

# Get the sid for the path
try {
    $sid = Get-ADUser -Identity $userName -ErrorAction Stop | Select-Object -ExpandProperty SID
}
catch {
    Write-Error "SID Not Found for $userName"
    exit
}

# todo: take account of naming conventions
$containingFolder = $userName + '_' + $sid

$vhdName = 'ODFC_' + $userName + $extension

$vhdPath = Join-Path $O365Folder (Join-Path $containingFolder $vhdName)

#are the prereqs present?
if ( -not (Test-Path $vhdPath)) {
    Write-Error 'VHD Not Found'
    exit
}

if (Test-Path HKLM:\SOFTWARE\FSLogix\Apps) {
    $InstallPath = (Get-ItemProperty HKLM:\SOFTWARE\FSLogix\Apps).InstallPath
}
else {
    Write-Error 'Install Not Found'
    exit
}

$frxPath = Join-Path $InstallPath frx.exe
if ( -not (Test-Path $frxPath )) {
    Write-Error 'frx.exe Not Found'
    exit
}

#mount vhd
try {
    $mountedDisk = Mount-DiskImage -ImagePath $vhdPath  -NoDriveLetter -PassThru -ErrorAction Stop | Get-DiskImage -ErrorAction Stop
}
catch {
    Write-Error 'Failed to mount disk'
    exit
}

#Assign vhd to a random path in temp
$tempGUID = New-Guid
$mountPath = Join-Path $Env:Temp

try {
    New-Item -Path $mountPath -ItemType Directory -ErrorAction Stop | Out-Null
}
catch {
    Write-Error 'Failed to create mounting directory'
    exit
}

try {
    Add-PartitionAccessPath -DiskNumber $mountedDisk.Number -PartitionNumber 1 -AccessPath $mountPath -ErrorAction Stop
}
catch {
    Write-Error 'Failed to create junction point'
    exit
}

# Now we have a path, remove dupe osts
Remove-FslMultiOst -Path (Join-Path $mountPath 'ODFC') -ErrorAction Stop

#copy the vhd
#todo: rename old vhd before mounting and copy contents to new of same name?  create temp first, then 
$newVHDName = Join-Path $Env:Temp ($tempGUID + $extension)

$label = 'O365-' + $userName

$argumentList = "copyto-vhd -filename=$newVHDName -src=$mountPath -dynamic=1 -label=$label"

Start-Process -FilePath $frxPath -ArgumentList $argumentList -Wait -NoNewWindow

try {
    Remove-PartitionAccessPath -DiskNumber $mountedDisk.Number -PartitionNumber 1 -AccessPath $mountPath -ErrorAction Stop
}
catch {
    Write-Warning 'Failed to remove junction point'
}

try {
    $mountedDisk | Dismount-DiskImage -ErrorAction Stop
}
catch {
    Write-Warning 'Failed to dismount disk'
}

try {
    Remove-Item -Path $mountPath -ErrorAction Stop
}
catch {
    Write-Warning "Failed to delete temp mount directory $mountPath"
}