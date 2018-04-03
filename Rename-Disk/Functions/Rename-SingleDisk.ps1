function Rename-SingleDisk {
    [CmdletBinding()]

    Param (
        [Parameter(
            Position = 0,
            ValuefromPipelineByPropertyName = $true,
            ValuefromPipeline = $true,
            Mandatory = $true
        )]
        [System.String]$Path,

        [Parameter(
            Position = 0,
            ValuefromPipelineByPropertyName = $true,
            Mandatory = $true
        )]
        [System.String]$NewName,

        [Parameter(
            Position = 0,
            ValuefromPipelineByPropertyName = $true,
            Mandatory = $true
        )]
        [string]$LogDir
    )

    BEGIN {
        Set-StrictMode -Version Latest
    } # Begin
    PROCESS {
        try{
            Rename-Item -Path $Path -NewName $NewName -ErrorAction Stop
            Write-Log "Renamed $Path to $NewName" -Path $LogDir
        }
        catch{
            Write-Log -Level Error "Failed to rename $Path" -Path $LogDir
        }
        
    } #Process
    END {} #End
}  #function Rename-SingleDisk