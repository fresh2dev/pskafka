function Get-KafkaTopics
{
	<#
	.DESCRIPTION
		Returns an array of Kafka topics.

	.PARAMETER BrokerList
		The Kafka broker(s) to connect to.
	.PARAMETER TopicName
		An optional wildcard string used to filter returned objects.

	.OUTPUTS
		A string array of Kafka topic names.
	.EXAMPLE
        Get-KafkaTopics -BrokerList 'localhost'
	#>
	[cmdletbinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$BrokerList,
        [string]$TopicName
	)
	
	$kafka = ConvertTo-TopicCommand -BrokerList $BrokerList

	[string[]]$output = & $kafka.path $kafka.args.Split(' ')

	if ([System.IO.Path]::GetFileNameWithoutExtension($kafka.path) -eq 'kafkacat') {
		$output = $output | Where-Object { $_ -match 'topic "(.+)"' } |
					Select-Object @{Name='Matches';Expression= {$Matches[1]}} |
					Select-Object -ExpandProperty Matches
	}

	return @($output | Where-Object { -not $TopicName -or ($_ -like $TopicName) } | Sort-Object)
}
