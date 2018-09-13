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
        [String]$ImagePath
    )

    BEGIN {
        Set-StrictMode -Version Latest
    } # Begin
    PROCESS {

        # FSLogix Disk Partition Number this won't work with vhds created with MS tools as their main partition number is 2
        $partitionNumber = 1

        # Reverse the three tasks from Mount-FslDisk
        try {
            Remove-PartitionAccessPath -DiskNumber $DiskNumber -PartitionNumber $partitionNumber -AccessPath $Path -ErrorAction Stop
        }
        catch {
            Write-Error "Failed to remove the junction point to $Path"
        }

        try {
            Dismount-DiskImage -ImagePath $ImagePath -ErrorAction Stop
        }
        catch {
            Write-Error "Failed to dismount disk $ImagePath"
        }

        try {
            Remove-Item -Path $Path -ErrorAction Stop
        }
        catch {
            Write-Error "Failed to delete temp mount directory $Path"
        }
    } #Process
    END {} #End
}  #function Dismount-FslDisk