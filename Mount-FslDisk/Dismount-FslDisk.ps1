function Dismount-FslDisk {
    [CmdletBinding()]

    Param (
        [Parameter(
            Position = 1,
            ValuefromPipelineByPropertyName = $true,
            ValuefromPipeline = $true,
            Mandatory = $true
        )]
        [String]$Path,

        [Parameter(
            ValuefromPipelineByPropertyName = $true,
            ValuefromPipeline = $true,
            Mandatory = $true
        )]
        [int16]$DiskNumber,

        [Parameter(
            ValuefromPipelineByPropertyName = $true,
            Mandatory = $true
        )]
        [String]$ImagePath,

        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [Switch]$PassThru    )

    BEGIN {
        Set-StrictMode -Version Latest
    } # Begin
    PROCESS {

        # FSLogix Disk Partition Number this won't work with vhds created with MS tools as their main partition number is 2
        $partitionNumber = 1

        # Reverse the three tasks from Mount-FslDisk
        try {
            Remove-PartitionAccessPath -DiskNumber $DiskNumber -PartitionNumber $partitionNumber -AccessPath $Path -ErrorAction Stop
            $junctionPointRemoved = $true
        }
        catch {
            Write-Error "Failed to remove the junction point to $Path"
        }

        try {
            Dismount-DiskImage -ImagePath $ImagePath -ErrorAction Stop
            $mountRemoved = $true
        }
        catch {
            Write-Error "Failed to dismount disk $ImagePath"
        }

        try {
            Remove-Item -Path $Path -ErrorAction Stop
            $directoryRemoved = $true
        }
        catch {
            Write-Error "Failed to delete temp mount directory $Path"
        }

        If ($PassThru) {
            $output = [PSCustomObject]@{
                JunctionPointRemoved = $junctionPointRemoved
                MountRemoved         = $mountRemoved
                DirectoryRemoved     = $directoryRemoved
            }
            Write-Output $output
        }
    } #Process
    END {} #End
}  #function Dismount-FslDisk