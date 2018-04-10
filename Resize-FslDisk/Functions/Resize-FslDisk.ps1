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
        [System.String[]]$PathToDisk,

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

        <#
        [Parameter(
            Position = 0,
            ValuefromPipelineByPropertyName = $true
        )]
        [switch]$AsJob,
        #>

        [Parameter(
            Position = 0,
            ValuefromPipelineByPropertyName = $true
        )]
        [switch]$NewLog,
        

        [Parameter(
            Position = 0,
            ValuefromPipelineByPropertyName = $true
        )]
        [string]$LogPath = "$env:TEMP\Resize-FslDisk.log"
    )

    BEGIN {
        Set-StrictMode -Version Latest
        #Write-Log.ps1
        $PSDefaultParameterValues = @{
            "Write-Log:Path" = "$LogPath"
            "Write-Log:Verbose" = $false
        }

        if ($NewLog){
            Write-Log -StartNew
            $NewLog = $false
        }

        if ((Get-Module -ListAvailable -Verbose:$false).Name -notcontains 'Hyper-V') {
            Write-Log -Level Error 'Hyper-V Powershell module not present'
            Write-Error 'Hyper-V Powershell module not present'
            exit
        }

    } # Begin
    PROCESS {
        switch ($PSCmdlet.ParameterSetName) {
            Folder {
                $vhds = Get-ChildItem -Path $Folder -Recurse -File -Filter *.vhd*
                if ($vhds.count -eq 0){
                    Write-Error "No vhd(x) files found in location $Folder"
                    Write-Log -Level Error "No vhd(x) files found in location $Folder"
                }
            }
            File {
                $vhds = foreach ($disk in $PathToDisk){
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

        foreach ($vhd in $vhds){
            try{
                $ResizeVHDParams = @{
                    #Passthru = $Passthru
                    #AsJob = $AsJob
                    SizeBytes = $SizeBytes
                    ErrorAction = 'Stop'
                    Path = $vhd.FullName
                }
                Resize-VHD @ResizeVHDParams
            }
            catch{
                Write-Log -Level Error "$vhd has not been resized"
            }

            try {
                $mount = Mount-VHD $vhd -Passthru -ErrorAction Stop
            }
            catch {
               $Error[0] | Write-Log
                Write-Log -level Error "Failed to mount $vhd"
                Write-Log -level Error "Stopping processing $vhd"
                break
            }

            try{
                $partitionNumber = 1
                $max = $mount | Get-PartitionSupportedSize -PartitionNumber $partitionNumber -ErrorAction Stop | Select-Object -ExpandProperty Sizemax
                $mount | Resize-Partition -size $max -PartitionNumber $partitionNumber -ErrorAction Stop
            }
            catch{
                $Error[0] | Write-Log
                Write-Log -level Error "Failed to resize partition on $vhd"
                Write-Log -level Error "Stopping processing $vhd"
                break
            }

            try {
                Dismount-VHD $vhd -ErrorAction Stop
                Write-Verbose "$vhd has been resized to $SizeBytes Bytes"
                Write-Log "$vhd has been resized to $SizeBytes Bytes"
            }
            catch {
                $Error[0] | Write-Log
                write-log -level Error "Failed to Dismount $vhd vhd will need to be manually dismounted"
            }
        }
    } #Process
    END {} #End
}  #function Resize-FslDisk