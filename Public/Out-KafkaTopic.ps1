function Out-KafkaTopic
{
	<#
	.DESCRIPTION
		Encapsulates `Start-KafkaProducer` and `Stop-KafkaConsumer` in one command.
		For parameter info, consult the documentation for these commands.

	.PARAMETER Producer
		If an existing producer process is passed, it will be reused.
	.PARAMETER Format
		The format to serialize messages. Can be 'json' (default) or 'text'.
	.PARAMETER PassThru
		When specified, messages are passed through the pipeline.

	.OUTPUTS
		None, unless `-PassThru` is specified.
	.EXAMPLE
		'hello world' | Out-KafkaTopic -BrokerList 'localhost:9092' -TopicName 'test'
		# or
		$p = Start-KafkaProducer -BrokerList 'localhost:9092' -TopicName 'test'
		1..3 | ForEach-Object { 'hello world' } | Out-KafkaTopic -Producer $p
		$p | Stop-KafkaProducer
	#>
	[cmdletbinding(DefaultParameterSetName='Connect')]
	param (
		[Parameter(Mandatory=$true, ValueFromPipeline=$true)]
		[object[]]$Messages,

		[Parameter(Mandatory=$true, ParameterSetName='UseProducer')]
		[System.Diagnostics.Process]$Producer,

		[Parameter(Mandatory=$true, ParameterSetName='Connect')]
		[string]$TopicName,
		[Parameter(ParameterSetName='Connect')]
		[string[]]$BrokerList = @('localhost:9092'),
		[Parameter(ParameterSetName='Connect')]
		[uint64]$TimeoutMS = 1000,
		[Parameter(ParameterSetName='Connect')]
		[uint32]$BatchSize = 100,
		[Parameter(ParameterSetName='Connect')]
		[uint16]$MaxRetries = 3,
		[Parameter(ParameterSetName='Connect')]
		[string]$Arguments,

		[Parameter(ParameterSetName='Connect')]
		[ValidateSet('json', 'text')]
		[string]$Format = 'json',

		[switch]$PassThru
	)

	begin {
		[bool]$keep_alive = $true
		if (-not $Producer) {
			$Producer = Start-KafkaProducer -TopicName $TopicName -BrokerList $BrokerList -TimeoutMS $TimeoutMS -BatchSize $BatchSize -MaxRetries $MaxRetries -Arguments $Arguments -ErrorAction Stop
			$keep_alive = $false
		}

		[scriptblock]$convert_obj = $null

		if ($Format -eq 'json') {
			$convert_obj = {
				param([object]$obj)
				return $($obj | ConvertTo-Json -Compress)
			}
		}
		else {
			$convert_obj = {
				param([object]$obj)
				return $($obj | Out-String -NoNewline)
			}
		}
	}
	process {
		foreach ($msg in $Messages) {
			$Producer.StandardInput.WriteLine($(& $convert_obj $msg))
			if ($PassThru) {
				Write-Output $msg
			}
		}
	}
	end {
		if (-not $keep_alive) {
			$null = $Producer | Stop-KafkaProducer
		}
	}
}
