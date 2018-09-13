function Mount-FslDisk {
    [CmdletBinding()]

    Param (
        [Parameter(
            Position = 0,
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

        #FSLogix Disk Partition Number
        $partitionNumber = 1

        try {
            $mountedDisk = Mount-DiskImage -ImagePath $Path -NoDriveLetter -PassThru -ErrorAction Stop | Get-DiskImage -ErrorAction Stop
        }
        catch {
            Write-Error 'Failed to mount disk'
            exit
        }

        #Assign vhd to a random path in temp
        $tempGUID = [guid]::NewGuid().ToString()
        $mountPath = Join-Path $Env:Temp $tempGUID

        try {
            New-Item -Path $mountPath -ItemType Directory -ErrorAction Stop | Out-Null
        }
        catch {
            Write-Error "Failed to create mounting directory $mountPath"
            #cleanup
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
            #cleanup
            Remove-Item -Path $mountPath -ErrorAction SilentlyContinue
            $mountedDisk | Dismount-DiskImage -ErrorAction SilentlyContinue
            exit
        }

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
