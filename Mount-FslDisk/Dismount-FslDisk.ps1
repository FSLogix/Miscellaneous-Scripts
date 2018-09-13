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

        try {
            Remove-PartitionAccessPath -DiskNumber $DiskNumber -PartitionNumber 2 -AccessPath $Path -ErrorAction Stop
        }
        catch {
            Write-Warning 'Failed to remove junction point'
        }

        try {
            Dismount-DiskImage -ImagePath $ImagePath -ErrorAction Stop 
        }
        catch {
            Write-Warning 'Failed to dismount disk'
        }
        

        
        catch {
            Write-Warning "Failed to delete temp mount directory $mountPath"
        }
    } #Process
    END {} #End
}  #function Dismount-FslDisk