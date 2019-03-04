function ConvertTo-TopicCommand
{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$BrokerList,
        [string]$Arguments
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
        $kafka.args = "-b $($BrokerList -join ',') -L"
    }
    else {
        if ($is_win) {
            $kafka.path = [System.IO.Path]::Combine($kafka.path, 'bin', 'windows', 'kafka-topics.bat')
        }
        else {
            $kafka.path = [System.IO.Path]::Combine($kafka.path, 'bin', 'kafka-topics.sh')
        }

        if (-not (Test-Path $kafka.path)) {
            Write-Error -Exception $([System.IO.FileNotFoundException]::new($kafka.path))
        }

        $kafka.args = "--zookeeper $($BrokerList -join ',') --list"
    }

    if ($Arguments) {
        $kafka.args += ' ' + $Arguments
    }

    Write-Verbose $("{0} {1}" -f $kafka.path, $kafka.args)

    return $kafka
}
