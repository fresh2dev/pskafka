function ConvertTo-ProducerCommand
{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$BrokerList,
        [Parameter(Mandatory=$true)]
        [string]$TopicName,

        [string]$Arguments,
        [uint64]$TimeoutMS = 1000,
        [uint32]$BatchSize = 200,
        [uint16]$MaxRetries = 3
    )

    [pscustomobject]$kafka = [pscustomobject]@{'path'=$null;'args'=$null}

    $kafka.path = Get-KafkaHome

    [string]$kafkacat = [System.IO.Path]::Combine($kafka.path, 'kafkacat')

    [bool]$is_win = $($PSVersionTable.PSVersion.Major -lt 6 -or $IsWindows)

    if ($is_win) {
        $kafkacat += '.exe'
    }

    if (Test-Path $kafkacat) {
        $kafka.path = $kafkacat
        $kafka.args = "-b $($BrokerList -join ',') -t $TopicName -P -X message.send.max.retries=$MaxRetries"

        if ($TimeoutMS -gt 0) {
            $kafka.args += ",queue.buffering.max.ms=$TimeoutMS"
        }
        if ($BatchSize -gt 0) {
            $kafka.args += ",queue.buffering.max.messages=$BatchSize"
        }
    }
    else {
        if ($is_win) {
            $kafka.path = [System.IO.Path]::Combine($kafka.path, 'bin', 'windows', 'kafka-console-producer.bat')
        }
        else {
            $kafka.path = [System.IO.Path]::Combine($kafka.path, 'bin', 'kafka-console-producer.sh')
        }

        if (-not (Test-Path $kafka.path)) {
            Write-Error -Exception $([System.IO.FileNotFoundException]::new($kafka.path))
        }

        $kafka.args = "--broker-list $($BrokerList -join ',') --topic $TopicName --message-send-max-retries $MaxRetries"

        if ($TimeoutMS -gt 0) {
            $kafka.args += " --timeout $TimeoutMS"
        }
        if ($BatchSize -gt 0) {
            $kafka.args += " --batch-size $BatchSize"
        }
    }

    if ($Arguments) {
        $kafka.args += ' ' + $Arguments
    }

    Write-Verbose $("{0} {1}" -f $kafka.path, $kafka.args)

    return $kafka
}
