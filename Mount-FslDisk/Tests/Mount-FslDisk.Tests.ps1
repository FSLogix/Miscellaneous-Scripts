$here = Split-Path -Parent $MyInvocation.MyCommand.Path | Split-Path -Parent
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. $here\$sut

Describe "Testing $($sut.trimend('.ps1'))" {

    Context "run" {
        Mock -CommandName Mount-DiskImage -MockWith {
            [PSCustomObject]@{
                ImagePath = 'TestDrive:/FakeMount.vhd'
            }
        }
        Mock -CommandName Get-DiskImage -MockWith {
            [PSCustomObject]@{
                Number    = 3
                ImagePath = 'TestDrive:/FakeMount.vhd'
            }
        }
        Mock -CommandName New-Item -MockWith { $null }


        Add-PartitionAccessPath
    }

    Context 'Cleanup' {
        #Cleanup
        Dismount-DiskImage
        Remove-Item
    }

}