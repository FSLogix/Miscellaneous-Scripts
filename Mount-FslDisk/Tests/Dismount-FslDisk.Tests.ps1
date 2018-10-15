$here = Split-Path -Parent $MyInvocation.MyCommand.Path | Split-Path -Parent
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. $here\$sut

Describe "Testing $($sut.trimend('.ps1'))" {
    Mock -CommandName Remove-PartitionAccessPath -MockWith { $null }
    Mock -CommandName Dismount-DiskImage  -MockWith { $null }
    Mock -CommandName Remove-Item  -MockWith { $null }

    $path = "$env:temp\guid"
    $dn = 2
    $im = "Testdrive:\FakeDisk.vhdx"

    Context 'Input' {
        It 'Testing named parameters' {
            $result = Dismount-FslDisk -Path $path -DiskNumber $dn -ImagePath $im -PassThru
            $result.directoryRemoved | Should -BeTrue
        }
        It 'Test Positional Params' {
            $result = Dismount-FslDisk $path -DiskNumber $dn -ImagePath $im -PassThru
            $result.directoryRemoved | Should -BeTrue
        }
        It 'Test Pipe by value String Params' {
            $result = $path | Dismount-FslDisk -DiskNumber $dn -ImagePath $im -PassThru
            $result.directoryRemoved | Should -BeTrue
        }
        It 'Test Pipe by value Int Params' {
            $result = $dn | Dismount-FslDisk $path -ImagePath $im -PassThru
            $result.directoryRemoved | Should -BeTrue
        }
        It 'Pipe by property name' {
            $pipe = [PSCustomObject]@{
                Path       = $path
                DiskNumber = $dn
                ImagePath  = $im
                Passthru   = $true
            }

            $result = $pipe | Dismount-FslDisk
            $result.directoryRemoved | Should -BeTrue
        }

    }

    Context 'Execution' {
        Mock -CommandName Remove-PartitionAccessPath -MockWith { Throw 'Pester Error' }
    }

    Context 'Output'{    
        It 'Gives no output when Passthru not stated' {
            $result = Dismount-FslDisk -Path $path -DiskNumber $dn -ImagePath $im
            $result | Should -BeNullOrEmpty
        }
    }
}