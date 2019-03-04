function Stop-KafkaProducer
{
	<#
	.DESCRIPTION
		Closes the standard input stream of a producer process and waits for it to exit.

	.PARAMETER Producer
		The producer process to stop.
	.PARAMETER TimeoutMS
		The maximum number of milliseconds to wait for the process to end gracefully after closing STDIN.
	.PARAMETER Force
		If $true and process did not end gracefully, terminate the process.
		
	.OUTPUTS
		Boolean (T/F) indicating whether or not the process was stopped.
	.EXAMPLE
		$p = Start-KafkaProducer ...
		$p | Stop-KafkaProducer -TimeoutMS 5000 -Force
	#>
	[cmdletbinding()]
	param (
		[Parameter(Mandatory=$true, ValueFromPipeline=$true)]
		[System.Diagnostics.Process]$Producer,
		[uint32]$TimeoutMS = 0,
		[switch]$Force
	)
	process {
		[bool]$exited = $Producer.HasExited

		if (-not $exited) {
			$Producer.StandardInput.Close()
			
			if ($TimeoutMS -eq 0) {
				$Producer.WaitForExit()
				$exited = $Producer.HasExited
			}
			else {
				$exited = $Producer.WaitForExit($TimeoutMS)
			}
			
			if (-not $exited -and $Force) {
				Write-Warning 'Terminating Producer.'
				$Producer.Kill()
				$exited = $true
			}
		}
		
		return $exited
	}
}
