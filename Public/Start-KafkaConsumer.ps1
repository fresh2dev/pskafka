function Start-KafkaConsumer
{
	<#
	.DESCRIPTION
		Starts a Kafka consumer process in a dedicated thread.
	.PARAMETER TopicName
		The Kafka topic from which messages will be consumed.
	.PARAMETER BrokerList
		The Kafka broker(s) to connect to.
	.PARAMETER Instances
		The number of consumers to start.
	.PARAMETER Arguments
		Custom arguments passed to the Kafka CLI.
	.PARAMETER ConsumerGroup
		The name of a Kafka consumer group to store offsets and distribute workload.
	.PARAMETER Persist
		If specified, the consumer will continue to poll the Kafka topic even after consuming the last available message.
	.PARAMETER FromBeginning
		If specified (and no stored offset already exists), the consumer will read from the beginning of the topic instead of the end.
	.OUTPUTS
		An array of ThreadJob objects, one for each new consumer.
	.EXAMPLE
		$c = Start-KafkaConsumer -BrokerList 'localhost:9092' -TopicName 'test'
	#>

	[cmdletbinding()]
    param(
		[Parameter(Mandatory=$true, ValueFromPipeline=$true)]
		[string[]]$TopicName,
        [Parameter(Mandatory=$true)]
        [string[]]$BrokerList,
		[ValidateRange(1, 9999)]
		[uint16]$Instances = 1,
		[string]$Arguments,
		
        [string]$ConsumerGroup,
        [uint64]$MessageCount = 0,
        [switch]$Persist,
		[switch]$FromBeginning
	)
	
	process {
		foreach ($topic in $TopicName)
		{
			$kafka = ConvertTo-ConsumerCommand -BrokerList $BrokerList -TopicName $topic -Arguments $Arguments -ConsumerGroup $ConsumerGroup -MessageCount $MessageCount -Persist:$Persist -FromBeginning:$FromBeginning

			1..$Instances | ForEach-Object {
				Start-ThreadJob -ArgumentList $kafka.path, $kafka.args.Split(' '), $ErrorActionPreference, $VerbosePreference, $WarningPreference, $DebugPreference -ScriptBlock {
					param([string]$FilePath, [string[]]$ArgumentList,
							$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop,
							$VerbosePreference = [System.Management.Automation.ActionPreference]::Continue,
							$WarningPreference = [System.Management.Automation.ActionPreference]::Continue,
							$DebugPreference = [System.Management.Automation.ActionPreference]::Continue)

					if (-not $ArgumentList) {
						& $FilePath
					} elseif ($ArgumentList.Length -eq 1) {
						& $FilePath $ArgumentList[0]
					} else {
						& $FilePath $ArgumentList
					}

					if ($LASTEXITCODE -ne $null) {
						Write-Debug $LASTEXITCODE
					} else {
						Write-Debug $([int](-not $?))
					}
				} -Verbose -ErrorAction 'Continue' -WarningAction 'Continue' -Debug
			}
		}
	}
}
