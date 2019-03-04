function Start-KafkaProducer
{
	<#
	.DESCRIPTION
		Starts a Kafka producer process.

	.PARAMETER TopicName
		The destination Kafka topic to which the producer will publish messages.
	.PARAMETER BrokerList
		The Kafka broker(s) to connect to.
	.PARAMETER BatchSize
		Wait for this many messages before sending a batch of messages.
	.PARAMETER TimeoutMS
		Wait this many milliseconds for the number of queued messages to reach BatchSize before sending.
	.PARAMETER MaxRetries
		Specifies how many times to retry on message send failure.
	.PARAMETER Arguments
		Custom arguments passed to the Kafka CLI.
		
	.OUTPUTS
		A System.Diagnostics.Process object of the new producer process.
	.EXAMPLE
		$p = Start-KafkaProducer -BrokerList 'localhost:9092' -TopicName 'test'
	#>
	[cmdletbinding()]
	param (
		[Parameter(Mandatory=$true)]
		[string]$TopicName,
		[string[]]$BrokerList = @('localhost:9092'),
		[uint32]$BatchSize = 100,
		[uint64]$TimeoutMS = 1000,
		[uint16]$MaxRetries = 3,
		[string]$Arguments
	)

	$kafka = ConvertTo-ProducerCommand @PSBoundParameters

	[System.Diagnostics.ProcessStartInfo]$psi = New-Object -TypeName System.Diagnostics.ProcessStartInfo ($kafka.path, $kafka.args)
	$psi.RedirectStandardInput = $true
	$psi.RedirectStandardOutput = $true
	$psi.RedirectStandardError = $true
	$psi.UseShellExecute = $false

	$p = New-Object -TypeName System.Diagnostics.Process
	$p.StartInfo = $psi
	$null = $p.Start()

	return $p
}
