$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$here = Split-Path $here
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe 'Resize-FslDisk' {

    BeforeAll {
        . ..\Write-Log.ps1
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "")]
        $size = 1073741824
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "")]
        $path = 'testdrive:\test.vhd'
    }

    Mock -CommandName Resize-VHD -MockWith {} -Verifiable
    Mock -CommandName Test-Path -MockWith { $true }
    Mock -CommandName Get-ChildItem -MockWith { Write-Output @{
        FullName = $path
    }}

    It 'Does not throw'{
        { Resize-FslDisk -SizeBytes $size -Path $path  } | should not throw
    }

    It 'Does not write Errors' {
        $errors = Resize-FslDisk -SizeBytes $size -Path $path 2>&1  
        $errors.count | should Be 0
    }

    It 'Writes a Verbose line' {
        $verbose = Resize-FslDisk -SizeBytes $size -Path $path -Verbose 4>&1  
        $verbose.count | should Be 1
    }

    It 'Asserts all verifiable mocks' {
        Assert-VerifiableMocks
    }

    It 'Takes pipeline input'{

    }
}