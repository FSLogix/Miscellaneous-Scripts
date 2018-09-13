function Dismount-FslDisk {
    [CmdletBinding()]

    Param (
        [Parameter(
            Position = 0,
            ValuefromPipelineByPropertyName = $true,
            ValuefromPipeline = $true,
            Mandatory = $true
        )]
        [String]$Path,

        [Parameter(
            Position = 1,
            ValuefromPipelineByPropertyName = $true,
            ValuefromPipeline = $true,
            Mandatory = $true
        )]
        [int16]$DiskNumber,

        [Parameter(
            Position = 2,
            ValuefromPipelineByPropertyName = $true,
            Mandatory = $true
        )]
        [String]$ImagePath
    )

    BEGIN {
        Set-StrictMode -Version Latest
    } # Begin
    PROCESS {

        $partitionNumber = 1

        try {
            Remove-PartitionAccessPath -DiskNumber $DiskNumber -PartitionNumber $partitionNumber -AccessPath $Path -ErrorAction Stop
        }
        catch {
            Write-Error "Failed to remove junction point $Path"
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