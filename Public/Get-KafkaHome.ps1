function Get-KafkaHome
{
    <#
	.DESCRIPTION
        Attempts to find the ideal Kafka CLI to use.

        If the environment variable `KAFKA_HOME` is set, it is used;
        else if the `-Default` parameter is given, it is used;
        else if a `kafkacat` executable exists in PATH, it is used;
        else, the (hopefully) appropriate `kafkacat` instance shipped with pskafka is used.
    #>
    param([string]$Default)

    $path = [System.Environment]::GetEnvironmentVariable('KAFKA_HOME')

    if ($path) {
        $path = $path
    }
    elseif ($Default) {
        $path = $Default
    }
    else {
        [string]$path = Get-Command 'kafkacat' -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty Path
        
        if ($path) {
            $path = Split-Path $path -Parent
        }
        else {
            [string]$os_dir = $null

            if ($IsLinux) {
                $os_dir = 'deb'
            }
            elseif ($IsMacOS) {
                $os_dir = 'mac'
            }
            else { #if ($IsWindows) {
                $os_dir = 'win'
            }

            $path = [System.IO.Path]::Combine((Get-Module 'pskafka').ModuleBase, 'bin', $os_dir)
        }
    }

    return $($path | Resolve-Path | Select-Object -ExpandProperty Path)
}
