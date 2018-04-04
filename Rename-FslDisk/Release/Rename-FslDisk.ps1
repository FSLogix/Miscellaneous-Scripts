function Rename-Disk {
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
            ValuefromPipeline = $true,
            Mandatory = $true
        )]
        [System.String]$Folder,

        [Parameter(
            Position = 0,
            ValuefromPipelineByPropertyName = $true,
            ValuefromPipeline = $true,
            Mandatory = $true
        )]
        [regex]$OriginalMatch = "^(.*?)_S-\d-\d+-(\d+-){1,14}\d+$",

        [Parameter(
            Position = 0,
            ValuefromPipelineByPropertyName = $true,
            Mandatory = $true
        )]
        [string]$MatchesArrayNumber = 1,

        [Parameter(
            Position = 0,
            ValuefromPipelineByPropertyName = $true,
            Mandatory = $true
        )]
        [string]$LogPath = "$env:TEMP\Rename-FslDisk.log"

    )

    BEGIN {
        Set-StrictMode -Version Latest
        #Write-Log
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
        #Rename-SingleDisk
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
            Files {
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
                $newName = $Matches["$MatchesArrayNumber"]
                Rename-SingleDisk -Path $file -NewName $newName -LogDir $LogPath
            }
            else{
                Write-Log -Level Warn "$file does not match regex"
            }
        }

    } #Process
    END {} #End
}  #function Rename-Disk
