function Read-Job
{
	<#
	.DESCRIPTION
		Continuously reads the various output streams from a ThreadJob.

	.PARAMETER Job
		The job(s) from which to read output streams.
	.PARAMETER TimeoutMS
		Stop polling if no new data has been received in `x` milliseconds (default=0; no timeout).
	.PARAMETER PollMS
		The number of milliseconds to wait in between each poll (default=250ms; 4 times per sec).
	.PARAMETER Tee
		When specified, output written to standard output as well as passed down the pipeline.
	.PARAMETER AutoRemoveJob
		When specified, job(s) will be stopped and disposed of upon completion.

	.OUTPUTS
		An array of output (if any) from the ThreadJob(s).
	.EXAMPLE
		Start-ThreadJob { ... } | Read-Job -TimeoutMS 5000 -AutoRemoveJob
	#>
	[cmdletbinding()]
	param(
		[Parameter(ValueFromPipeline=$true)]
		[object[]]$Job,
		[uint64]$TimeoutMS = 0,
		[uint32]$PollMS = 250,
		[switch]$Tee,
		[switch]$AutoRemoveJob
	)
	
	begin {
		[System.Collections.ArrayList]$jobs = New-Object System.Collections.ArrayList
	}

	process {
		foreach ($j in $Job) {
			if ($j -isnot [ThreadJob.ThreadJob] -and $j -isnot [System.Management.Automation.Job]) {
				throw [System.InvalidOperationException]::new('Job must be ThreadJob or PSRemotingJob')
			}
			else {
				$null = $jobs.Add($j)
			}
		}
	}

	end {
		[uint16]$n_alive = 0
		$timer = New-Object System.Diagnostics.Stopwatch
		$timer.Start()

		try {
			do
			{
				$n_alive = 0
				Start-Sleep -Milliseconds $PollMS

				foreach ($j in $jobs) {
					if ($j.HasMoreData) {
						$j | Read-JobStreams -Tee:$Tee
						$timer.Restart()
					}
					if ($j.State -eq [System.Management.Automation.JobState]::Running) {
						$n_alive++
					}
				}
			} while ($n_alive -gt 0 -and ($TimeoutMS -eq 0 -or $timer.ElapsedMilliseconds -lt $TimeoutMS))

			$timer.Stop()

			if ($TimeoutMS -eq 0) {
				$null = $jobs | Wait-Job -Force
			}

			if ($AutoRemoveJob) {
				$jobs | Stop-Job
			}

			$jobs | Read-JobStreams -Tee:$Tee
		}
		finally {
			if ($timer -and $timer.IsRunning) {
				$timer.Stop()
			}
			if ($AutoRemoveJob) {
				$null = $jobs | Remove-Job -Force
			}
		}
	}
}
