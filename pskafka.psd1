@{
	# Script module or binary module file associated with this manifest.
	RootModule = 'pskafka.psm1'

	# Version number of this module.
	ModuleVersion = '0.1.0'

	# Supported PSEditions
	CompatiblePSEditions = 'Desktop', 'Core'

	# ID used to uniquely identify this module
	GUID = '8e9db64e-1090-46af-b9ed-2102279ac40f'

	# Author of this module
	Author = 'Donald Mellenbruch'

	# Company or vendor of this module
	# CompanyName = 'Unknown'

	# Copyright statement for this module
	Copyright = '(c) 2019 Donald Mellenbruch. All rights reserved.'

	# Description of the functionality provided by this module
	Description = 'Provides a PowerShell wrapper around the Kafka CLI / kafkacat.'

	# Minimum version of the PowerShell engine required by this module
	PowerShellVersion = '5.1'

	# Name of the PowerShell host required by this module
	# PowerShellHostName = ''

	# Minimum version of the PowerShell host required by this module
	# PowerShellHostVersion = ''

	# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
	# DotNetFrameworkVersion = ''

	# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
	# CLRVersion = ''

	# Processor architecture (None, X86, Amd64) required by this module
	# ProcessorArchitecture = ''

	# Modules that must be imported into the global environment prior to importing this module
	RequiredModules = @('ThreadJob')

	# Assemblies that must be loaded prior to importing this module
	# RequiredAssemblies = ''

	# Script files (.ps1) that are run in the caller's environment prior to importing this module.
	# ScriptsToProcess = ''

	# Type files (.ps1xml) to be loaded when importing this module
	# TypesToProcess = @()

	# Format files (.ps1xml) to be loaded when importing this module
	# FormatsToProcess = @()

	# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
	# NestedModules = @()

	# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
	FunctionsToExport  = @('Get-KafkaTopics', 'Start-KafkaProducer', 'Start-KafkaConsumer', 'Stop-KafkaProducer', 'Read-KafkaTopic', 'Set-KafkaHome', 'Send-Messages', 'Read-Job', 'Read-JobStreams', 'Out-KafkaTopic', 'Get-KafkaHome')

	# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
	CmdletsToExport    = @()

	# Variables to export from this module
	VariablesToExport  = @()

	# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
	AliasesToExport    = @('Read-KafkaTopic', 'Read-KafkaConsumer', 'Stop-KafkaConsumer', 'Get-KafkaConsumer', 'Receive-KafkaConsumer', 'Wait-KafkaConsumer', 'Remove-KafkaConsumer')

	# DSC resources to export from this module
	# DscResourcesToExport = @()

	# List of all modules packaged with this module
	# ModuleList = @()

	# List of all files packaged with this module
    FileList = './pskafka.psd1',
				'./pskafka.psm1',
				'./README.md',
				'./README.Rmd',
				'./bin/win/format.obj',
				'./bin/win/getdelim.obj',
				'./bin/win/kafkacat.exe',
				'./bin/win/kafkacat.obj',
				'./bin/win/librdkafka.dll',
				'./bin/win/librdkafkacpp.dll',
				'./bin/win/msvcr120.dll',
				'./bin/win/tools.obj',
				'./bin/win/wingetopt.obj',
				'./bin/win/zlib.dll',
				'./bin/deb/kafkacat',
				'./bin/mac/kafkacat',
				'./Examples/test.ps1',
				'./Private/ConvertTo-ConsumerCommand.ps1',
				'./Private/ConvertTo-ProducerCommand.ps1',
				'./Private/ConvertTo-TopicCommand.ps1',
				'./Public/Get-KafkaHome.ps1',
				'./Public/Get-KafkaTopics.ps1',
				'./Public/Out-KafkaTopic.ps1',
				'./Public/Read-Job.ps1',
				'./Public/Read-JobStreams.ps1',
				'./Public/Read-KafkaTopic.ps1',
				'./Public/Set-KafkaHome.ps1',
				'./Public/Start-KafkaConsumer.ps1',
				'./Public/Start-KafkaProducer.ps1',
				'./Public/Stop-KafkaProducer.ps1'

	# HelpInfo URI of this module
	HelpInfoURI = 'https://www.github.com/dm3ll3n/pskafka'

	# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
	PrivateData = @{
		PSData = @{
			# Tags applied to this module. These help with module discovery in online galleries.
			Tags = 'Kafka'

			# A URL to the license for this module.
			# LicenseUri = ''

			# A URL to the main website for this project.
			ProjectUri = 'https://www.github.com/dm3ll3n/pskafka'

			# A URL to an icon representing this module.
			# IconUri = ''

			# ReleaseNotes of this module
			ReleaseNotes = 'https://www.github.com/dm3ll3n/pskafka'
		} # End of PSData hashtable
	} # End of PrivateData hashtable

	# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
	# DefaultCommandPrefix = ''
}