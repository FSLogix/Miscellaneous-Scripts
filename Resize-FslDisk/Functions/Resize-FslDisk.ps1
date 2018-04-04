function Resize-FslDisk {
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
            ValuefromPipeline = $true,
            Mandatory = $true
        )]
        [uint64]$SizeBytes,

        [Parameter(
            Position = 0,
            ValuefromPipelineByPropertyName = $true
        )]
        [switch]$AsJob,

        [Parameter(
            Position = 0,
            ValuefromPipelineByPropertyName = $true
        )]
        [switch]$Passthru,

        [Parameter(
            Position = 0,
            ValuefromPipelineByPropertyName = $true
        )]
        [string]$LogPath = "$env:TEMP\Resize-FslDisk.log"
    )

    BEGIN {
        Set-StrictMode -Version Latest
        #Write-Log

        if ((Get-Module -ListAvailable).Name -notcontains 'Hyper-V') {
            Write-Log -Level Error 'Hyper-V Powershell module not present'
            Write-Error 'Hyper-V Powershell module not present'
            exit
        }
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
            try{
                $ResizeVHDParams = @{
                    Passthru = $Passthru
                    AsJob = $AsJob
                    SizeBytes = $SizeBytes
                    ErrorAction = 'Stop'
                    Path = $file
                }
                Resize-VHD @ResizeVHDParams
                Write-Log "$file has been resized to $SizeBytes Bytes"
            }
            catch{
                Write-Log -Level Error "$file has not been resized"
            }
        }
    } #Process
    END {} #End
}  #function Resize-FslDisk