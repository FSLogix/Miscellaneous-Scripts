function Rename-FslDisk {
    [CmdletBinding()]

    Param (
        [Parameter(
            ParameterSetName = 'File',
            Position = 0,
            ValuefromPipelineByPropertyName = $true,
            ValuefromPipeline = $true,
            Mandatory = $true
        )]
        [System.String]$PathToDisk,

        [Parameter(
            ParameterSetName = 'Folder',
            Position = 0,
            ValuefromPipelineByPropertyName = $true,
            Mandatory = $true
        )]
        [System.String]$Folder,

        [Parameter(
            Position = 0,
            ValuefromPipelineByPropertyName = $true,
            ValuefromPipeline = $true
        )]
        [regex]$OriginalMatch = "^(.*?)_S-\d-\d+-(\d+-){1,14}\d+$",

        [Parameter(
            Position = 0,
            ValuefromPipelineByPropertyName = $true
        )]
        [string]$MatchesArrayNumber = 1,

        [Parameter(
            Position = 0,
            ValuefromPipelineByPropertyName = $true
        )]
        [string]$LogPath = "$env:TEMP\Rename-FslDisk.log"

    )

    BEGIN {
        Set-StrictMode -Version Latest
        #Write-Log
        #Rename-SingleDisk
        $PSDefaultParameterValues = @{"Write-Log:Path" = "$LogPath"}
    } # Begin
    PROCESS {
        switch ($PSCmdlet.ParameterSetName) {
            Folder {
                $files = Get-ChildItem -Path $Folder -Recurse -File -Filter *.vhd*
                if ($files.count -eq 0){
                    Write-Error "No files found in location $Folder" 
                    Write-Log -Level Error "No files found in location $Folder" 
                }
            }
            File {
                $files = foreach ($disk in $PathToDisk){
                    if (Test-Path $disk){
                        Get-ChildItem -Path $disk
                    }
                    else{
                        Write-Error "$disk does not exist"
                        Write-Log -Level Error "$disk does not exist"
                    }
                }
            }
        } #switch

        foreach ($file in $files){
            if ($file.BaseName -match $OriginalMatch){
                $newName = "Profile_$($Matches[1])$($file.Extension)"
                Rename-SingleDisk -Path $file -NewName $newName -LogPath $LogPath
            }
            else{
                Write-Log -Level Warn "$file does not match regex"
            }
        }

    } #Process
    END {} #End
}  #function Rename-FslDisk