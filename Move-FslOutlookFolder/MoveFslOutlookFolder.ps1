function Move-FslOulookFolder {
    [CmdletBinding(PositionalBinding=$true)]

    Param (
        [Parameter(
            ValuefromPipelineByPropertyName = $true,
            ValuefromPipeline = $true,
            Mandatory = $true
        )]
        [System.String[]]$User,

        [Parameter(
            ValuefromPipelineByPropertyName = $true,
            ValuefromPipeline = $true,
            Mandatory = $true
        )]
        [System.String]$ProfilePath,

        [Parameter(
            ValuefromPipelineByPropertyName = $true,
            ValuefromPipeline = $true,
            Mandatory = $true
        )]
        [System.String[]]$O365Path
    )

    BEGIN {
        Set-StrictMode -Version Latest
        #Requires -Modules "Hyper-V"
        #Requires -Modules "ActiveDirectory"
        #Requires -RunAsAdministrator
    } # Begin
    PROCESS {

        #get-sid for username

        #Mount profile VHD

        #Mount 0365 VHD

        #Copy Oulook folder

        #DisMount profile VHD

        #DisMount 0365 VHD

    } #Process
    END {} #End
}  #function Move-FslOulookFolder