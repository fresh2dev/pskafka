function Read-KafkaTopic
{
	<#
	.DESCRIPTION
		Encapsulates `Start-KafkaConsumer`, `Read-KafkaConsumer`, and `Stop-KafkaConsumer` in one command.
		For parameter info, consult the documentation for these commands.
	.OUTPUTS
		An array of messages consumed from the topic.
	.EXAMPLE
		Read-KafkaTopic -BrokerList 'localhost:9092' -TopicName 'test' -MessageCount 10 -FromBeginning
	#>
	[cmdletbinding(DefaultParameterSetName='UseConsumer')]
	param (
		[Parameter(Mandatory=$true, ValueFromPipeline=$true, ParameterSetName='UseConsumer')]
		[ThreadJob.ThreadJob[]]$Consumer,

		[Parameter(Mandatory=$true, ValueFromPipeline=$true, ParameterSetName='Connect')]
		[string[]]$TopicName,
		[Parameter(Mandatory=$true, ParameterSetName='Connect')]
        [string[]]$BrokerList,
		[Parameter(ParameterSetName='Connect')]
		[ValidateRange(1, 9999)]
		[uint16]$Instances = 1,
		[Parameter(ParameterSetName='Connect')]
		[string]$Arguments,
		
		[Parameter(ParameterSetName='Connect')]
		[string]$ConsumerGroup,
		[Parameter(ParameterSetName='Connect')]
		[uint64]$MessageCount = 0,
		[Parameter(ParameterSetName='Connect')]
		[switch]$Persist,
		[Parameter(ParameterSetName='Connect')]
		[switch]$FromBeginning,

		[Parameter(ParameterSetName='UseConsumer')]
		[Parameter(ParameterSetName='Connect')]
		[uint64]$TimeoutMS = 0,
		[Parameter(ParameterSetName='UseConsumer')]
		[Parameter(ParameterSetName='Connect')]
		[uint32]$PollMS = 250,
		[Parameter(ParameterSetName='UseConsumer')]
		[Parameter(ParameterSetName='Connect')]
		[switch]$Tee,
		[Parameter(ParameterSetName='UseConsumer')]
		[switch]$AutoRemoveJob
	)

	begin {
		if (-not $Consumer) {
			$Consumer = Start-KafkaConsumer -TopicName $TopicName -BrokerList $BrokerList -Instances $Instances -Arguments $Arguments -ConsumerGroup $ConsumerGroup -MessageCount $MessageCount -Persist:$Persist -FromBeginning:$FromBeginning
			$AutoRemoveJob = $true
		}
	}

	process {
		$Consumer | Read-KafkaConsumer -TimeoutMS $TimeoutMS -PollMS $PollMS -Tee:$Tee -AutoRemoveJob:$AutoRemoveJob
	}
}