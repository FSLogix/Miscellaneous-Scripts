$here = Split-Path -Parent $MyInvocation.MyCommand.Path | Split-Path -Parent
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. $here\$sut

Describe "Testing $($sut.trimend('.ps1'))" {

    $fakeDisk = 'TestDrive:\MadeUp.vhdx'

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
    Mock -CommandName Remove-Item -MockWith { $null }
    Mock -CommandName Dismount-DiskImage -MockWith { $null }

    Context "Input" {

        It 'Runs with Named Parameter' {
            $result = Mount-FslDisk -Path $fakeDisk -PassThru
            $result.Path | Should -not -BeNullOrEmpty
        }

        It 'Runs with Positional Parameter' {
            $result = Mount-FslDisk $fakeDisk -PassThru
            $result.Path | Should -not -BeNullOrEmpty
        }

        It 'Runs with Pipeline by value' {
            $result = $fakeDisk | Mount-FslDisk -PassThru
            $result.Path | Should -not -BeNullOrEmpty
        }

        It 'Runs with Pipeline by named value' {
            $pipe = [PSCustomObject]@{
                ImagePath = $fakeDisk
            }
            $result = $pipe | Mount-FslDisk -PassThru
            $result.Path | Should -not -BeNullOrEmpty
        }
    }

    Context 'Execution with no errors' {

        Mount-FslDisk -Path $fakeDisk

        It 'Does not call Remove-Item mock' {

            Assert-MockCalled -CommandName Remove-Item -Times 0
        }
        It 'Does not call Dismount-DiskImage mock' {
            Assert-MockCalled -CommandName Dismount-DiskImage -Times 0
        }
        It 'Calls New-Item mock Once' {
            Assert-MockCalled -CommandName New-Item -Times 1
        }
        It 'Calls Mount-DiskImage mock Once' {
            Assert-MockCalled -CommandName Mount-DiskImage -Times 1
        }
        It 'Calls Get-DiskImage mock Once' {
            Assert-MockCalled -CommandName Get-DiskImage -Times 1
        }
        It 'Calls Add-PartitionAccessPath mock Once' {
            Assert-MockCalled -CommandName Add-PartitionAccessPath -Times 1
        }
    }

    Context 'Execution with Mount Error' {

        Mock -CommandName Mount-DiskImage -MockWith {
            Throw 'pester mount error'
        }

        It 'Fails With correct error at mount' {
            Mount-FslDisk -Path $fakeDisk -ErrorVariable mnt -ErrorAction SilentlyContinue | Out-Null
            $mnt[-1].Exception.Message | Should -BeLike "Failed to mount disk*"
        }

        It 'Does not continue script' {
            Assert-MockCalled -CommandName Get-DiskImage -Times 0
        }
    }

    Context 'Execution with New-item Error' {

        Mock -CommandName New-Item -MockWith {
            Throw 'pester New-item error'
        }

        It 'Fails With correct error at New-item' {
            Mount-FslDisk -Path $fakeDisk -ErrorVariable itm -ErrorAction SilentlyContinue | Out-Null
            $itm[-1].Exception.Message | Should -BeLike "Failed to create mounting directory*"
        }

        It 'Does not continue script' {
            Assert-MockCalled -CommandName Add-PartitionAccessPath -Times 0
        }
        It 'Does Run Cleanup' {
            Assert-MockCalled -CommandName  Dismount-DiskImage -Times 1
        }
    }

    Context 'Execution with Add-PartitionAccessPath Error' {

        Mock -CommandName Add-PartitionAccessPath -MockWith {
            Throw 'pester Add-PartitionAccessPath error'
        }

        Mock -CommandName Write-Output -MockWith {
            'Fake Output'
        }

        $prt = $null

        It 'Fails With correct error at Add-PartitionAccessPath' {
            Mount-FslDisk -Path $fakeDisk -ErrorVariable prt -ErrorAction SilentlyContinue | Out-Null
            $prt[-1].Exception.Message | Should -BeLike "Failed to create junction point to *"
        }

        It 'Does not continue script' {
            Assert-MockCalled -CommandName Write-Output -Times 0
        }
        It 'Does Run Mount Cleanup' {
            Assert-MockCalled -CommandName  Dismount-DiskImage -Times 1
        }
        It 'Does Run Directory Cleanup' {
            Assert-MockCalled -CommandName  Remove-Item -Times 1
        }
    }

    Context 'Output' {
        $result = Mount-FslDisk -Path 'fakedisk.vhdx' -PassThru

        It 'Has three properties' {
            $result | Get-Member -MemberType NoteProperty | Should -HaveCount 3
        }

        It 'Has the correct ImagePath' {
            $result.ImagePath | Should -Be 'TestDrive:\MadeUp.vhdx'
        }

        It 'Has the correct DiskNumber' {
            $result.DiskNumber | Should -Be 3
        }

        It 'Has the correct Prefix in Path' {
            $result.Path | Split-Path -Leaf | Should -BeLike "FSLogixMnt-*"
        }

        It 'Has a GUID in Path' {
            $guid = ($result.Path | Split-Path -Leaf).TrimStart('FSLogixMnt-')
            try {
                [guid]$guid
                $test = $true
            }
            catch {
                $test = $false
            }
            $test | Should -BeTrue
        }
    }
}