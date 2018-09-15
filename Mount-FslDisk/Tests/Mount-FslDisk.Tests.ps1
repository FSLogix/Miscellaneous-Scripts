$here = Split-Path -Parent $MyInvocation.MyCommand.Path | Split-Path -Parent
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. $here\$sut

Describe "Testing $($sut.trimend('.ps1'))" {

    $fakeDisk = 'TestDrive:\MadeUp.vhdx'

    Context "Input" {

        Mock -CommandName Mount-DiskImage -MockWith {
            [PSCustomObject]@{
                ImagePath = $fakeDisk
            }
        }
        Mock -CommandName Get-DiskImage -MockWith {
            [PSCustomObject]@{
                Number    = 3
                ImagePath = $fakeDisk
            }
        }
        Mock -CommandName New-Item -MockWith { $null }

        Mock -CommandName Add-PartitionAccessPath -MockWith { $null }

        It 'Runs with Named Parameter' {
            $result = Mount-FslDisk -Path $fakeDisk
            $result.Path | Should -not -BeNullOrEmpty
        }

        It 'Runs with Positional Parameter' {
            $result = Mount-FslDisk $fakeDisk
            $result.Path | Should -not -BeNullOrEmpty
        }

        It 'Runs with Pipeline by value' {
            $result = $fakeDisk | Mount-FslDisk
            $result.Path | Should -not -BeNullOrEmpty
        }

        It 'Runs with Pipeline by named value' {
            $pipe = [PSCustomObject]@{
                ImagePath = $fakeDisk
            }
            $result = $pipe | Mount-FslDisk
            $result.Path | Should -not -BeNullOrEmpty
        }



    }

    Context 'Execution' {
        #Cleanup
        #Dismount-DiskImage
        #Remove-Item
    }

}