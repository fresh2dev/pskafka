function Set-KafkaHome
{
    <#
	.DESCRIPTION
		Sets the `KAFKA_HOME` environment variable for the session.

	.PARAMETER Path
		The value to set `KAFKA_HOME`.

	.OUTPUTS
		None
	.EXAMPLE
        Set-KafkaHome '~/kafka' # to use Kafka CLI
        Set-KafkaHome $null     # to revert to kafkacat
	#>
    param(
        [string]$Path,
        [System.EnvironmentVariableTarget]$Scope = [System.EnvironmentVariableTarget]::Process
    )

    if ($Path) {
        if (-not (Test-Path $Path)) {
            throw [System.IO.DirectoryNotFoundException]::new($Path)
        }
    }
    [System.Environment]::SetEnvironmentVariable('KAFKA_HOME', $Path, $Scope)
}
