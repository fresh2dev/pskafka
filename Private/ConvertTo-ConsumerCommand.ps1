function ConvertTo-ConsumerCommand
{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$BrokerList,
        [Parameter(Mandatory=$true)]
        [string]$TopicName,
        [string]$Arguments,
        [string]$ConsumerGroup,
        [switch]$FromBeginning,
        [uint64]$MessageCount = 0,
        [switch]$Persist
    )

    if ($MessageCount -gt 0 -and $Persist) {
        throw $([System.InvalidOperationException]::new('Cannot specify both `-MessageCount` and `-Persist`'))
    }

    [pscustomobject]$kafka = [pscustomobject]@{'path'=$null;'args'=$null}

    $kafka.path = Get-KafkaHome

    [string]$kafkacat = [System.IO.Path]::Combine($kafka.path, 'kafkacat')

    [bool]$is_win = $($PSVersionTable.PSVersion.Major -lt 6 -or $IsWindows)

    if ($is_win) {
        $kafkacat += '.exe'
    }

    if (Test-Path $kafkacat) {
        $kafka.path = $kafkacat
        $kafka.args = "-b $($BrokerList -join ',') -q -u"

        if ($FromBeginning) {
            if ($ConsumerGroup) {
                $kafka.args += ' -X auto.offset.reset=earliest'
            }
            else {
                $kafka.args += ' -o beginning'
            }
        }

        if ($MessageCount -gt 0) {
            $kafka.args += " -c $MessageCount -e"
        }
        elseif (-not $Persist) {
            $kafka.args += ' -e'
        }

        if ($ConsumerGroup) {
            $kafka.args += " -G $ConsumerGroup $TopicName"
        }
        else {
            $kafka.args += " -C -t $TopicName"
        }
    }
    else {
        if ($is_win) {
            $kafka.path = [System.IO.Path]::Combine($kafka.path, 'bin', 'windows', 'kafka-console-consumer.bat')
        }
        else {
            $kafka.path = [System.IO.Path]::Combine($kafka.path, 'bin', 'kafka-console-consumer.sh')
        }
        
        if (-not (Test-Path $kafka.path)) {
            Write-Error -Exception $([System.IO.FileNotFoundException]::new($kafka.path))
        }

        $kafka.args = "--bootstrap-server $($BrokerList -join ',') --topic $TopicName"

        if ($ConsumerGroup) {
            $kafka.args += " --group $ConsumerGroup"
        }

        if ($FromBeginning) {
            $kafka.args += ' --from-beginning'
        }

        if ($MessageCount -gt 0) {
            $kafka.args += " --max-messages $MessageCount"
        }
        elseif (-not $Persist) {
            $kafka.args += " --timeout-ms 10000"
        }
    }

    if ($Arguments) {
        $kafka.args += ' ' + $Arguments
    }

    Write-Verbose $("{0} {1}" -f $kafka.path, $kafka.args)

    return $kafka
}
