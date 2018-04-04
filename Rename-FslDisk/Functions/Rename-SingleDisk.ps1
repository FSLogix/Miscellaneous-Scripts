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
        [string]$LogPath
    )

    BEGIN {
        Set-StrictMode -Version Latest
        $PSDefaultParameterValues = @{"Write-Log:Path" = "$LogPath"}
    } # Begin
    PROCESS {
        try{
            Rename-Item -Path $Path -NewName $NewName -ErrorAction Stop
            Write-Log "Renamed $Path to $NewName"
            Write-Verbose "Renamed $Path to $NewName"
        }
        catch{
            Write-Log -Level Error "Failed to rename $Path"
        }
    } #Process
    END {} #End
}  #function Rename-SingleDisk