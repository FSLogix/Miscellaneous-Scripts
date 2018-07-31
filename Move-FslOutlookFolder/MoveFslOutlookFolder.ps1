function Move-FslOulookFolder {
    [CmdletBinding(PositionalBinding = $true)]

    Param (
        [Parameter(
            ValuefromPipelineByPropertyName = $true,
            ValuefromPipeline = $true,
            Mandatory = $true
        )]
        [System.String[]]$User,

        [Parameter(
            ValuefromPipelineByPropertyName = $true,
            Mandatory = $true
        )]
        [System.String]$ProfilePath,

        [Parameter(
            ValuefromPipelineByPropertyName = $true,
            Mandatory = $true
        )]
        [System.String]$O365Path,

        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [System.String]$LogPath = "$Env:TEMP\Move-FslOulookFolder.log"
    )

    BEGIN {
        Set-StrictMode -Version Latest
        #Requires -Modules "Hyper-V"
        #Requires -Modules "ActiveDirectory"
        #Requires -RunAsAdministrator
    } # Begin
    PROCESS {

        foreach ($account in $User) {

            #Need the SID for the path
            try {
                $accountSID = Get-ADUser -Identity $account -ErrorAction Stop | Select-Object -ExpandProperty SID
            }
            catch {
                $error[0] | Write-Log
                Write-Log -Level Error -Message "Cannot find SID for $account, Stopping processing"
                break
            }

            #Create Flip/Flop paths, won't work if customer has default path values or vhd disk files
            try{
            $profileVHDPath = Join-Path -Path $ProfilePath -ChildPath (Join-Path -Path $account + '_' + $accountSID -ChildPath 'Profile_' + $account + '.vhdx' -ErrorAction Stop) -ErrorAction Stop

            $o365VHDPath = Join-Path -Path $O365Path -ChildPath (Join-Path -Path $account + '_' + $accountSID -ChildPath 'ODFC_' + $account + '.vhdx' -ErrorAction Stop) -ErrorAction Stop
            }
            catch{
                $error[0] | Write-Log
                Write-Log -Level Error -Message "Cannot create vhd location paths for $account, Stopping processing"
                break
            }
            
            #make sure vhdxs really exist
            if (-not (Test-Path -Path $profileVHDPath)){
                Write-Log -Level Error -Message "Cannot find $profileVHDPath, Stopping processing $account"
                break
            }
    
            if (-not (Test-Path -Path $o365VHDPath)){
                Write-Log -Level Error -Message "Cannot find $o365VHDPath, Stopping processing $account"
                break
            }

            #get last 2 free drive letters
            $freeDrives = [char[]](68..90) | Where-Object { -not (Test-Path ($_ + ':')) } | Select-Object -Last 2

            if (($freeDrives | Measure-Object | Select-Object -ExpandProperty count) -lt 2){
                Write-Log -Level Warning 'Not enough free drive letters, trying to free spare'
                Write-Warning 'Not enough free drive letters, trying to free spare letters'
                get-disk | Where-Object {$_.FriendlyName -eq "Msft Virtual Disk"} | Select-Object -ExpandProperty location | Dismount-DiskImage
                $freeDrives = [char[]](68..90) | Where-Object { -not (Test-Path ($_ + ':')) } | Select-Object -last 2
            }
            
            #Mount both disks and assign a free drive letter
            try{
                Mount-VHD -Path $profileVHDPath -NoDriveLetter -Passthru -ErrorAction Stop | Get-Disk | Get-Partition | Where-Object { $_.type -eq 'Basic' } | Set-Partition -NewDriveLetter $freeDrives[0]
            }
            catch{
                $error[0] | Write-Log
                Write-Log -Level Error -Message "Cannot Mount profile disk for $account, Stopping processing"
                break
            }

            try{
                Mount-VHD -Path $o365VHDPath -NoDriveLetter -Passthru -ErrorAction Stop | Get-Disk | Get-Partition | Where-Object { $_.type -eq 'Basic' } | Set-Partition -NewDriveLetter $freeDrives[1]
            }
            catch{
                $error[0] | Write-Log
                Write-Log -Level Error -Message "Cannot mount o365 disk for $account, Stopping processing"
                break
            }

            #Move Oulook folder
            try {
                Move-Item ( Join-Path -Path $freeDrives[0] -ChildPath 'ODFC\Outlook' ) -Destination ( Join-Path -Path $freeDrives[1] -ChildPath 'ODFC\Outlook' ) -Force
            }
            catch {
                $error[0] | Write-Log
                Write-Log -Level Error -Message "Cannot move Outlook folder for $account, Stopping processing"
                break
            }

            try{
                DisMount-VHD -Path $o365VHDPath -ErrorAction Stop
            }
            catch{
                $error[0] | Write-Log
                Write-Log -Level Warning -Message "Cannot DisMount o365 disk for $account"
                Write-Warning "Cannot DisMount o365 disk for $account"
            }

            try{
                DisMount-VHD -Path $profileVHDPath -ErrorAction Stop
            }
            catch{
                $error[0] | Write-Log
                Write-Log -Level Warning -Message "Cannot DisMount profile disk for $account"
                Write-Warning "Cannot DisMount profile disk for $account"
            }
        }
    } #Process
    END {} #End
}  #function Move-FslOulookFolder