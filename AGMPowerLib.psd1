#
# Module manifest for module 'AGMPowerLib'
#
# Generated by: Anthony Vandewerdt
#
# Generated on: 10/7/2020
#

@{

# Script module or binary module file associated with this manifest.
RootModule = 'AGMPowerLib.psm1'

# Version number of this module.
ModuleVersion = '0.0.0.21'

# Supported PSEditions
# CompatiblePSEditions = @()

# ID used to uniquely identify this module
GUID = '6155fdbc-7393-48a8-a7ac-9f5f69f8887b'

# Author of this module
Author = 'Anthony Vandewerdt'

# Company or vendor of this module
CompanyName = 'Actifio'

# Copyright statement for this module
Copyright = '(c) 2020 Actifio, Inc. All rights reserved'

################################################################################################################## 
# Description of the functionality provided by this module
Description = 'This is a community generated PowerShell Module for Actifio Global Manager (AGM).  
It provides composite functions that combine commands to various AGM API endpoints, to achieve specific outcomes. 
Examples include mounting a database, creating a new VM or running a workflow.
More information about this module can be found here:   https://github.com/Actifio/AGMPowerLib'

# Minimum version of the PowerShell engine required by this module
PowerShellVersion = '5.0'

# Name of the PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# ClrVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
RequiredModules = @('AGMPowerCLI')

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = @('Get-AGMLibActiveImage',
'Get-AGMLibApplicationID',
'Get-AGMLibAppPolicies',
'Get-AGMLibContainerYAML',
'Get-AGMLibHostID',
'Get-AGMLibImageDetails',
'Get-AGMLibImageRange',
'Get-AGMLibFollowJobStatus',
'Get-AGMLibLastPostCommand',
'Get-AGMLibLatestImage',
'Get-AGMLibPolicies',
'Get-AGMLibRunningJobs',
'Get-AGMLibWorkflowStatus',
'New-AGMLibAWSVM',
'New-AGMLibAzureVM',
'New-AGMLibContainerMount',
'New-AGMLibFSMount',
'New-AGMLibGCPVM',
'New-AGMLibImage',
'New-AGMLibMSSQLMount',
'New-AGMLibVM',
'New-AGMLibMultiVM',
'New-AGMLibOracleMount',
'New-AGMLibMSSQLMigrate',
'New-AGMLibSystemStateToVM',
'New-AGMLibVMExisting',
'Restore-AGMLibMount',
'Set-AGMLibMSSQLMigrate',
'Start-AGMLibWorkflow')

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = '*'

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = '*'

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = @("Actifio","AGM","Sky","CDS","CDX","VDP")

        # A URL to the license for this module.
        LicenseUri = 'https://github.com/Actifio/AGMPowerLib/blob/master/LICENSE'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/Actifio/AGMPowerLib'

        # A URL to an icon representing this module.
        IconUri = 'https://i.imgur.com/QAaK5Po.jpg'

        # ReleaseNotes of this module
        ReleaseNotes = '
        ## [0.0.0.21] 2020-10-09
        Revamped New-AGMLibMSSQLMigrate and Set-AGMLibMSSQLMigrate with improved menus and help.  Enhanced imagestate column in Get-AGMLibActiveImage. Added migrate user story

        ## [0.0.0.20] 2020-09-20
        Improved module description for PowerShell Gallery users

        ## [0.0.0.17] 2020-09-18
        Fixed bad character issue with Get-AGMLibActiveImages

        ## [0.0.0.16] 2020-09-18
        Get-AGMLibApplicationID now offers -f for fuzzy search on appname
        PS5 compatability

        ## [0.0.0.15] 2020-09-11
        Add label to New-AGMLibImage
        Add Get-AGMLibAppPolicies, Start-AGMLibWorkflow,  Get-AGMLibWorkflowStatus, Get-AGMLibPolicies, New-AGMLibFSMount
        Change New-AGMLibOracleMount and New-AGMLibMSSQLMount so you do not need to select mount appliance.

        ## [0.0.0.14] 2020-09-05
        Changed most variables from int to string as some appliances have numbers that exceed int32 boundaries

        ## [0.0.0.13] 2020-09-04
        Added Restore-AGMLibMount to rewind child apps
        Improved New-AGMLibOracleMount and New-AGMLibMSSQLMount to check for mount appliance and offer management of child app

        ## [0.0.0.12] 2020-09-02
        NewVM menus will show OnVault pool name during image selection
        Ensure AGMPowerCLI is installed by making it a required module

        ## [0.0.0.11] 2020-08-26
        Improved Get-AGMLibActiveImage
        System State recovery will now look for latest image if that is what is wanted

        ## [0.0.0.10] 2020-08-24
        Improved Get-AGMLibActiveImage
        added appliance test to System State mounts as well as enforce manadatory fields

        ## [0.0.0.9] 2020-08-23
        Added New-AGMLibAzureVM and New-AGMLibAWSVM
        Improved New-AGMLibSystemStateToVM, New-AGMLibGCPVM

        ## [0.0.0.8] 2020-08-21
        Added New-AGMLibOracleMount, Set-AGMLibMSSQLMigrate, New-AGMLibMSSQLMigrate, New-AGMLibSystemStateToVM, New-AGMLibGCPVM
        Improved New-AGMLibMultiVM
        Improved Get-AGMLibActiveImage
        Improved Get-AGMLibLastPostCommand to also offer flags for put or delete
        Added SLA ID to Get-AGMLibApplicationID
        

        ## [0.0.0.7] 2020-08-12
        Improved New-AGMLibMultiVM

        ## [0.0.0.6] 2020-08-11
        Improved New-AGMLibMultiVM and Get-AGMLibImageRange

        ## [0.0.0.5] 2020-08-10
        Improved New-AGMLibMultiVM
        Stop using format table for any output. 

        ## [0.0.0.4] 2020-08-09
        Added Get-AGMLibImageRange, New-AGMLibMultiVM
        Change Get-AGMLibActiveImage so that output is no longer a table

        ## [0.0.0.3] 2020-08-06
        Change NewVM to not require volumes.

        ## [0.0.0.2] 2020-07-21
        Added Container scripts, improved error handling, made guided mounts the default if user runs command without parms
                
        ## [0.0.0.1] 2020-07-20
        Initial Release'

        # Prerelease string of this module
        # Prerelease = ''

        # Flag to indicate whether the module requires explicit user acceptance for install/update/save
        # RequireLicenseAcceptance = $false

        # External dependent modules of this module
        # ExternalModuleDependencies = @()

    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}

