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

            try{
            $profileVHDPath = Join-Path -Path $ProfilePath -ChildPath (Join-Path -Path $account + '_' + $accountSID -ChildPath 'Profile_' + $account -ErrorAction Stop) -ErrorAction Stop

            $o365VHDPath = Join-Path -Path $O365Path -ChildPath (Join-Path -Path $account + '_' + $accountSID -ChildPath 'ODFC_' + $account -ErrorAction Stop) -ErrorAction Stop
            }
            catch{
                $error[0] | Write-Log
                Write-Log -Level Error -Message "Cannot create vhd location paths for $account, Stopping processing"
                break
            }
            if (-not (Test-Path -Path $profileVHDPath)){
                Write-Log -Level Error -Message "Cannot find $profileVHDPath, Stopping processing $account"
                break
            }
    
            if (-not (Test-Path -Path $o365VHDPath)){
                Write-Log -Level Error -Message "Cannot find $o365VHDPath, Stopping processing $account"
                break
            }




        }


        #Mount profile VHD

        #Mount 0365 VHD

        #Copy Oulook folder

        #DisMount profile VHD

        #DisMount 0365 VHD

    } #Process
    END {} #End
}  #function Move-FslOulookFolder