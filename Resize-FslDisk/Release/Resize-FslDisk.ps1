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
        [switch]$Passthru,

        [Parameter(
            Position = 0,
            ValuefromPipelineByPropertyName = $true
        )]
        [string]$LogPath = "$env:TEMP\Resize-FslDisk.log"
    )

    BEGIN {
        Set-StrictMode -Version Latest

        function Write-Log {
            [CmdletBinding(DefaultParametersetName = "LOG")]
            Param (
                [Parameter(Mandatory = $true,
                    ValueFromPipelineByPropertyName = $true,
                    Position = 0,
                    ParameterSetName = 'LOG')]
                [ValidateNotNullOrEmpty()]
                [string]$Message,

                [Parameter(Mandatory = $false,
                    Position = 1,
                    ParameterSetName = 'LOG')]
                [ValidateSet("Error", "Warn", "Info")]
                [string]$Level = "Info",

                [Parameter(Mandatory = $false,
                    Position = 2)]
                [string]$Path = "$env:temp\PowershellScript.log",

                [Parameter(Mandatory = $false,
                    Position = 3,
                    ParameterSetName = 'STARTNEW')]
                [switch]$StartNew,

                [Parameter(Mandatory = $false,
                    Position = 4,
                    ValueFromPipeline = $true,
                    ValueFromPipelineByPropertyName = $true,
                    ParameterSetName = 'EXCEPTION')]
                [System.Management.Automation.ErrorRecord]$Exception

            )

            BEGIN {
                Set-StrictMode -version Latest
                $expandedParams = $null
                $PSBoundParameters.GetEnumerator() | ForEach-Object { $expandedParams += ' -' + $_.key + ' '; $expandedParams += $_.value }
                Write-Verbose "Starting: $($MyInvocation.MyCommand.Name)$expandedParams"
            }
            PROCESS {

                switch ($PSCmdlet.ParameterSetName) {
                    EXCEPTION {
                        Write-Log -Level Error -Message $Exception.Exception.Message -Path $Path
                        break
                    }
                    STARTNEW {
                        Write-Verbose -Message "Deleting log file $Path if it exists"
                        Remove-Item $Path -Force -ErrorAction SilentlyContinue
                        Write-Verbose -Message 'Deleted log file if it exists'
                        Write-Log 'Starting Logfile' -Path $Path
                        break
                    }
                    LOG {
                        Write-Verbose 'Getting Date for our Log File'
                        $FormattedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                        Write-Verbose 'Date is $FormattedDate'

                        switch ( $Level ) {
                            'Error' { $LevelText = 'ERROR:  '; break }
                            'Warn'  { $LevelText = 'WARNING:'; break }
                            'Info'  { $LevelText = 'INFO:   '; break }
                        }

                        $logmessage = "$FormattedDate $LevelText $Message"
                        Write-Verbose $logmessage

                        $logmessage | Add-Content -Path $Path
                    }
                }

            }
            END {
                Write-Verbose "Finished: $($MyInvocation.Mycommand)"
            }
        } # enable logging

        $PSDefaultParameterValues = @{
            "Write-Log:Path" = "$LogPath"
            "Write-Log:Verbose" = $false
        }
        Write-Log -StartNew
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
                    Passthru = $Passthru
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
                $partitionNumber = 2
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
