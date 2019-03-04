function Read-JobStreams
{
	<#
	.DESCRIPTION
		Reads the various output streams from a ThreadJob. Used in `Read-Job` for obtaining live process output.

	.PARAMETER Job
		The job(s) from which to read output streams.
	.PARAMETER Streams
		The specific streams to read (defaults to all).
	.PARAMETER Tee
		When specified, output written to standard output as well as passed down the pipeline.

	.OUTPUTS
		An array of output (if any) from the ThreadJob.
	.EXAMPLE
		Start-ThreadJob { ... } | Read-JobStreams
	#>
	param(
		[Parameter(Mandatory=$true, ValueFromPipeline=$true)]
		[object[]]$Job,
		[string[]]$Streams = @('Output', 'Information', 'Verbose', 'Warning', 'Debug', 'Error'),
		[switch]$Tee
	)

	process
	{
		foreach ($i in $Job)
		{
			foreach ($j in @(@($i) + $i.ChildJobs))
			{
				foreach ($s in $Streams)
				{
					foreach ($d in $j."$s".ReadAll())
					{
						switch ($s) {
							'Verbose' { Write-Verbose $d; break; }
							'Warning' { Write-Warning $d; break; }
							'Debug' { Write-Debug $d; break; }
							'Error' { Write-Error $d; break; }
							Default {
								if ($Tee) {
									Write-Host $d
								}
								Write-Output $d
							}
						}
					}
				}
			}
		}
	}
}
