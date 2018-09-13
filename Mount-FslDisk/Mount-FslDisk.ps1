function Mount-FslDisk {
    [CmdletBinding()]

    Param (
        [Parameter(
            Position = 1,
            ValuefromPipelineByPropertyName = $true,
            ValuefromPipeline = $true,
            Mandatory = $true
        )]
        [alias('FullName')]
        [System.String]$Path
    )

    BEGIN {
        Set-StrictMode -Version Latest
    } # Begin
    PROCESS {

        # FSLogix Disk Partition Number this won't work with vhds created with MS tools as their main partition number is 2
        $partitionNumber = 1

        try {
            # Mount the disk without a drive letter and get it's info, Mount-DiskImage is used to remove reliance on Hyper-V tools
            $mountedDisk = Mount-DiskImage -ImagePath $Path -NoDriveLetter -PassThru -ErrorAction Stop | Get-DiskImage -ErrorAction Stop
        }
        catch {
            Write-Error 'Failed to mount disk'
            exit
        }

        # Assign vhd to a random path in temp folder so we don't have to worry about free drive letters which can be horrible
        # New-Guid not used here for PoSh 3 compatibility
        $tempGUID = [guid]::NewGuid().ToString()
        $mountPath = Join-Path $Env:Temp ('FSLogixMnt-' + $tempGUID)

        try {
            # Create directory which we will mount too
            New-Item -Path $mountPath -ItemType Directory -ErrorAction Stop | Out-Null
        }
        catch {
            Write-Error "Failed to create mounting directory $mountPath"
            # Cleanup
            $mountedDisk | Dismount-DiskImage -ErrorAction SilentlyContinue
            exit
        }

        try {

            $addPartitionAccessPathParams = @{
                DiskNumber      = $mountedDisk.Number
                PartitionNumber = $partitionNumber
                AccessPath      = $mountPath
                ErrorAction     = 'Stop'
            }

            Add-PartitionAccessPath @addPartitionAccessPathParams
        }
        catch {
            Write-Error "Failed to create junction point to $mountPath"
            # Cleanup
            Remove-Item -Path $mountPath -ErrorAction SilentlyContinue
            $mountedDisk | Dismount-DiskImage -ErrorAction SilentlyContinue
            exit
        }

        # Create output required for piping to Dismount-FslDisk
        $output = [PSCustomObject]@{
            Path       = $mountPath
            DiskNumber = $mountedDisk.Number
            ImagePath  = $mountedDisk.ImagePath
        }
        Write-Output $output

    } #Process
    END {

    } #End
}  #function Mount-FslDisk
