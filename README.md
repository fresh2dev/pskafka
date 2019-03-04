`pskafka`: Enhancing the Kafka CLI with Powershell flavor.

* [Overview](#overview)
* [Requirements](#requirements)
* [Topics](#topics)
* [Produce](#produce)
  * [Persistent Producer](#persistent-producer)
* [Consume](#consume)
  * [Simple Consumer](#simple-consumer)
  * [MultiTopic Consumer](#multitopic-consumer)
  * [Persistent Consumer](#persistent-consumer)
  * [Consumer Threads](#consumer-threads)
* [Powershell Object Example](#powershell-object-example)

Read this on [GitHub](https://github.com/dm3ll3n/pskafka) or [my
site](https://www.donaldmellenbruch.com/project/pskafka/).

## Overview

[Apache Kafka](https://kafka.apache.org/) is a useful publish &
subscribe messaging system. Data is transmitted, or “produced”, to a
Kafka as “messages” that are later retrieved, “consumed”, by any number
of recipients. A simple way of producing and consuming messages is with
the default Kafka command-line interface, which uses Java to interact
with a Kafka instance. Another Kafka CLI exists,
[kafkacat](https://github.com/edenhill/kafkacat), which depends on the
C/C++ library [librdkafka](https://github.com/edenhill/librdkafka). This
Powershell module, pskafka, wraps around *either* the default Kafka CLI,
or kafkacat, to provide the following:

1.  a syntax friendly to Powershell developers.
2.  easy reuse of Kafka producer(s) throughout a pipeline by
    communicating with the Kafka CLI over the standard input stream.
3.  easily spawn and read from multiple Kafka consumers in separate
    threads.

Powershell is an object-oriented scripting language that was recently
made open-source and cross-platform. Powershell can natively convert to
and from JSON, which is a common format in which Kafka messages are
produced. By parsing a JSON message into a Powershell object,
transformations in the command-line are made much easier.

pskafka has comment-based help (i.e., docstring) that can be explored
using Powershell’s help system.

``` powershell
Import-Module ./pskafka.psd1
# List all commands in the `pskafka` module.
Get-Command -Module pskafka | Select-Object CommandType, Name
```

    ## 
    ## CommandType Name
    ## ----------- ----
    ##       Alias Get-KafkaConsumer
    ##       Alias Read-KafkaConsumer
    ##       Alias Receive-KafkaConsumer
    ##       Alias Remove-KafkaConsumer
    ##       Alias Stop-KafkaConsumer
    ##       Alias Wait-KafkaConsumer
    ##    Function Get-KafkaHome
    ##    Function Get-KafkaTopics
    ##    Function Out-KafkaTopic
    ##    Function Read-Job
    ##    Function Read-JobStreams
    ##    Function Read-KafkaTopic
    ##    Function Set-KafkaHome
    ##    Function Start-KafkaConsumer
    ##    Function Start-KafkaProducer
    ##    Function Stop-KafkaProducer

``` powershell
Import-Module ./pskafka.psd1
# Get help for a command.
Get-Help -Name 'Start-KafkaConsumer'
```

    ## 
    ## NAME
    ##     Start-KafkaConsumer
    ##     
    ## SYNOPSIS
    ##     
    ##     
    ## SYNTAX
    ##     Start-KafkaConsumer [-TopicName] <String[]> [-BrokerList] <String[]> 
    ##     [[-Instances] <UInt16>] [[-Arguments] <String>] [[-ConsumerGroup] 
    ##     <String>] [[-MessageCount] <UInt64>] [-Persist] [-FromBeginning] 
    ##     [<CommonParameters>]
    ##     
    ##     
    ## DESCRIPTION
    ##     Starts a Kafka consumer process in a dedicated thread.
    ##     
    ## 
    ## RELATED LINKS
    ## 
    ## REMARKS
    ##     To see the examples, type: "get-help Start-KafkaConsumer -examples".
    ##     For more information, type: "get-help Start-KafkaConsumer -detailed".
    ##     For technical information, type: "get-help Start-KafkaConsumer -full".

## Requirements

-   A Kafka instance (if you don’t have one, follow steps 1-3 of the
    [Kafka quickstart guide](https://kafka.apache.org/quickstart)).
-   Powershell v5+ (if you’re on a non-Windows system, install
    [Powershell
    Core](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell)).
-   The `ThreadJob` module (ships with Powershell Core; if necessary,
    install with `Install-Module -Name 'ThreadJob'`).
-   The `pskafka` module, of course –&gt; install with
    `Install-Module -Name 'pskafka'`.

You will also need a local Kafka command-line interface, either
[kafkacat](https://github.com/edenhill/kafkacat) or the standard Kafka
CLI. `pskafka` ships with compiled builds of kafkacat v1.4.0RC1 for
Debian Linux, Mac, and Windows. Either CLI has dependencies of its own
that may need to be resolved; consult the documentation if necessary.

## Topics

First, get a list of all existing topics.

Using the Kafka CLI:

``` powershell
~/kafka/bin/kafka-topics.sh --zookeeper localhost --list
```

Using kafkacat:

``` powershell
./bin/deb/kafkacat -b localhost -L
```

Using pskafka:

``` powershell
Import-Module ./pskafka.psd1

Get-KafkaTopics -BrokerList localhost -Verbose
```

    ## VERBOSE: /home/donald/dev/pwsh/pskafka/bin/deb/kafkacat -b localhost -L
    ## __consumer_offsets
    ## test
    ## test_two

Notice that, with `-Verbose` specified, any pskafka command will output
the command issued to either CLI. Above, kafkacat was used, which ships
with pskafka. To use the Java-based Kafka CLI, or another instance of
kafkacat, specify the path in `KAFKA_HOME`. pskafka provides the command
`Set-KafkaHome`, which will set `KAFKA_HOME` for the session.

``` powershell
Import-Module ./pskafka.psd1

Set-KafkaHome '~/kafka'

Get-KafkaTopics -BrokerList localhost -Verbose
```

    ## VERBOSE: /home/donald/kafka/bin/kafka-topics.sh --zookeeper localhost --list
    ## __consumer_offsets
    ## test
    ## test_two

## Produce

When producing streams of messages, Kafka does so more efficiently by
queueing up messages until a specified message count has been reached or
time period has elapsed. A batch of messages is sent when one of either
threshold is reached.

Producing with the Kafka CLI:

``` powershell
0..9999 |
  Select-Object @{Name='TsTicks';Expression={(Get-Date).Ticks}}, `
                @{Name='Message'; Expression={ 'Hello world #' + $_.ToString() }} |
  ForEach-Object { $_ | ConvertTo-JSON -Compress } |
  ~/kafka/bin/kafka-console-producer.sh --broker-list 'localhost:9092' --topic 'test' --batch-size 100 --timeout 1000 | Out-Null
```

Producing with kafkacat:

``` powershell
0..9999 |
  Select-Object @{Name='TsTicks';Expression={(Get-Date).Ticks}}, `
                @{Name='Message'; Expression={ 'Hello world #' + $_.ToString() }} |
  ForEach-Object { $_ | ConvertTo-JSON -Compress } |
  ./bin/deb/kafkacat -b 'localhost:9092' -t 'test' -P -X queue.buffering.max.messages=100,queue.buffering.max.ms=1000
```

Producing with pskafka using `Out-KafkaTopic`:

``` powershell
Import-Module ./pskafka.psd1

0..9999 |
  Select-Object @{Name='TsTicks';Expression={(Get-Date).Ticks}}, `
                @{Name='Message'; Expression={ 'Hello world #' + $_.ToString() }} |
    Out-KafkaTopic -TopicName 'test' -BrokerList 'localhost:9092' -BatchSize 100 -Verbose -ErrorAction Stop
```

    ## VERBOSE: /home/donald/dev/pwsh/pskafka/bin/deb/kafkacat -b localhost:9092 -t test -P -X message.send.max.retries=3,queue.buffering.max.ms=1000,queue.buffering.max.messages=100

### Persistent Producer

A useful feature of pskafka is the ability to start a Kafka CLI producer
and write to it later. This allows for a more flexible workflow, such as
writing messages to Kafka topic(s) given a condition. The example below
first starts a Kafka producer, produces messages for a short duration,
then stops the producer.

``` powershell
Import-Module ./pskafka.psd1

# start producer process
$p = Start-KafkaProducer -TopicName 'test' -BrokerList 'localhost:9092' -BatchSize 100 -TimeoutMS 1000 -Verbose

# start a timer
$timer = New-Object System.Diagnostics.Stopwatch
$timer.Start()

for ($i = 0; $timer.Elapsed.TotalSeconds -lt 5; $i++)
{
  $obj = New-Object PSObject -Property @{
    'TsTicks'=(Get-Date).Ticks;
    'Message'="Hello Kafka #$i"
  }

  # write to producer process over STDIN.
  $obj | Out-KafkaTopic -Producer $p
}

# stop timer
$timer.Stop()

# stop producer
$p | Stop-KafkaProducer | Out-Null

Write-Host $("Produced {0} messages in {1} seconds." -f $i, [math]::Round($timer.Elapsed.TotalSeconds, 2))
```

    ## VERBOSE: /home/donald/dev/pwsh/pskafka/bin/deb/kafkacat -b localhost:9092 -t test -P -X message.send.max.retries=3,queue.buffering.max.ms=1000,queue.buffering.max.messages=100
    ## Produced 4086 messages in 5 seconds.

## Consume

Kafka consumers read messages from a topic. A consumer starts reading
from a specific *offset*, which is typically either:

1.  latest offset; the end of the topic messages (default).
2.  earliest offset; the beginning of the topic messages.
3.  stored offset; the offset stored for a consumer group.

A useful feature of Kafka is its ability to efficiently store offsets
for consumers in a “consumer group”. A stored offset allows a consumer
to beginning reading where it last left off. In addition, all consumers
in a group *share* the workload across Kafka topic partitions; no single
message is sent to two consumers in the same group.

### Simple Consumer

Offsets are not committed for a simple consumer, so a simple consumer
will either begin reading from the end of a topic (default) or the
beginning (if specified).

Consuming with Kafka CLI:

``` powershell
$messages = ~/kafka/bin/kafka-console-consumer.sh --bootstrap-server 'localhost:9092' --topic 'test' --max-messages 1000 --from-beginning

Write-Host $("{0} total messages consumed" -f $messages.Length)
```

    ## Processed a total of 1000 messages
    ## 1000 total messages consumed

Consuming with kafkacat:

``` powershell
$messages = ./bin/deb/kafkacat -C -b 'localhost:9092' -t 'test' -o beginning -c 1000

Write-Host $("{0} total messages consumed" -f $messages.Length)
```

    ## 1000 total messages consumed

Consuming with pskafka:

``` powershell
Import-Module ./pskafka.psd1

$messages = Read-KafkaTopic -TopicName 'test' -BrokerList 'localhost:9092' -MessageCount 1000 -FromBeginning -Verbose

Write-Host $("{0} total messages consumed" -f $messages.Length)
```

    ## VERBOSE: /home/donald/dev/pwsh/pskafka/bin/deb/kafkacat -b localhost:9092 -q -u -o beginning -c 1000 -e -C -t test
    ## 1000 total messages consumed

Consuming with pskafka (multiple consumers):

``` powershell
Import-Module ./pskafka.psd1

$messages = Read-KafkaTopic -TopicName 'test' -BrokerList 'localhost:9092' -Instances 3 -MessageCount 1000 -FromBeginning -Verbose

Write-Host $("{0} total messages consumed" -f $messages.Length)
Write-Host $("{0} unique messages consumed" -f @($messages | Select-Object -Unique).Length)
```

    ## VERBOSE: /home/donald/dev/pwsh/pskafka/bin/deb/kafkacat -b localhost:9092 -q -u -o beginning -c 1000 -e -C -t test
    ## 3000 total messages consumed
    ## 1000 unique messages consumed

In the example above, notice how three consumers were created
(`-Instances 3`), and 3,000 messages were consumed, but only 1,000 of
the messages are unique. This is because each consumer received the same
set of messages from the topic.

Consuming with pskafka (multiple consumers in consumer group):

In the example below, the three consumers are made part of the same
consumer group with the `-ConsumerGroup` parameter. Thus, all of the
3,000 consumed messages are distinct; i.e., each consumer received a
unique set of messages from the topic.

``` powershell
Import-Module ./pskafka.psd1

$messages = Read-KafkaTopic -TopicName 'test' -BrokerList 'localhost:9092' -ConsumerGroup 'my_consumer_group' -Instances 3 -MessageCount 1000 -FromBeginning -Verbose

Write-Host $("{0} total messages consumed" -f $messages.Length)
Write-Host $("{0} unique messages consumed" -f @($messages | Select-Object -Unique).Length)
```

    ## VERBOSE: /home/donald/dev/pwsh/pskafka/bin/deb/kafkacat -b localhost:9092 -q -u -X auto.offset.reset=earliest -c 1000 -e -G my_consumer_group test
    ## 3000 total messages consumed
    ## 3000 unique messages consumed

> Note that `-FromBeginning` is only applicable for a consumer group
> that does not already have a stored offset to read from.

### MultiTopic Consumer

Specify an array of topic names to `-TopicName` in order to spawn a
consumer for each topic. If `-Instances` is greater than 1, *each* topic
will get the number of instances (e.g., 3 topics w/ 2 instances each = 6
total instances).

``` powershell
Import-Module ./pskafka.psd1

$one = Read-KafkaTopic -TopicName 'test' -BrokerList 'localhost:9092' -FromBeginning -Verbose |
        Measure-Object | Select-Object -ExpandProperty Count

$two = Read-KafkaTopic -TopicName 'test_two' -BrokerList 'localhost:9092' -FromBeginning -Verbose |
        Measure-Object | Select-Object -ExpandProperty Count

$one_and_two = Read-KafkaTopic -TopicName 'test','test_two' -BrokerList 'localhost:9092' -FromBeginning -Verbose |
                Measure-Object | Select-Object -ExpandProperty Count
                
($one + $two) -eq $one_and_two
```

    ## VERBOSE: /home/donald/dev/pwsh/pskafka/bin/deb/kafkacat -b localhost:9092 -q -u -o beginning -e -C -t test
    ## VERBOSE: /home/donald/dev/pwsh/pskafka/bin/deb/kafkacat -b localhost:9092 -q -u -o beginning -e -C -t test_two
    ## VERBOSE: /home/donald/dev/pwsh/pskafka/bin/deb/kafkacat -b localhost:9092 -q -u -o beginning -e -C -t test
    ## VERBOSE: /home/donald/dev/pwsh/pskafka/bin/deb/kafkacat -b localhost:9092 -q -u -o beginning -e -C -t test_two
    ## True

### Persistent Consumer

By default, a consumer will exit soon after all topic messages have been
processed. Include the `-Persist` parameter to instruct a consumer
persist after reaching the end of a topic. The parameter `-TimeoutMS`
instructs the consumer to exit if no messages have been received within
the specified duration. Without this, the consumer would persist
indefinitely, passing messages down the pipeline as they arrive.

``` powershell
Import-Module ./pskafka.psd1

Read-KafkaTopic -TopicName 'test' -BrokerList 'localhost:9092' -ConsumerGroup 'my_consumer_group_3' -Instances 3 -FromBeginning -Persist -TimeoutMS 30000 -Verbose |
ForEach-Object `
  -Begin {
    $i=0
    $timer = New-Object System.Diagnostics.Stopwatch
    $timer.Start()
  } `
  -Process {
    $i++
    if ($i % 10000 -eq 0) {
      Write-Host $( '{0} msg/sec; {1} total messages.' -f ($i / $timer.Elapsed.TotalSeconds ).ToString(), $i )
    }
  } `
  -End {
    Write-Host "Consumed $i total messages."
    $timer.Stop()
  }
```

    ## VERBOSE: /home/donald/dev/pwsh/pskafka/bin/deb/kafkacat -b localhost:9092 -q -u -X auto.offset.reset=earliest -G my_consumer_group_3 test
    ## 1726.00749473878 msg/sec; 10000 total messages.
    ## 2323.40185529447 msg/sec; 20000 total messages.
    ## 2735.28886428345 msg/sec; 30000 total messages.
    ## Consumed 34086 total messages.

### Consumer Threads

The command `Read-KafkaTopic` actually encapsulates three aptly-named
commands:

1.  `Start-KafkaConsumer`: invokes consumer processes in separate
    threads; consumers immediately begin consuming messages in
    background threads.
2.  `Read-KafkaConsumer`: reads and clears the output streams from a
    thread.
3.  `Stop-KafkaConsumer`: stops a thread.

The object returned from `Start-KafkaConsumer` is a
[ThreadJob](https://github.com/PaulHigin/PSThreadJob) that is compatible
with the standard Powershell commands (`Get-Job`, `Wait-Job`,
`Receive-Job`). In fact, the commands `Get-KafkaConsumer`,
`Wait-KafkaConsumer`, and `Receive-KafkaConsumer` are just aliases to
these native Powershell commands.

It is very easy to start a background consumer with
`Start-KafkaConsumer` and never read from or stop it. If this happens,
the consumer could read an unbounded number of messages until system
resources are exceeded. Be responsible with calls to
`Start-KafkaConsumer` by following up with `Read-KafkaConsumer` and
`Stop-KafkaConsumer`. When in doubt, kill all background jobs using
`Get-Job | Remove-Job -Force`.

## Powershell Object Example

Earlier, I alluded to Powershell’s powerful object-oriented approach to
the shell. I’ll conclude this walkthrough with an example that
illustrates this. The following example:

1.  reads messages in JSON format.
2.  converts them to a Powershell object.
3.  augments the original message.
4.  outputs new message to Kafka.
5.  outputs new message to a local CSV file.

<!-- -->

``` powershell
Import-Module ./pskafka.psd1

Read-KafkaTopic -TopicName 'test' -BrokerList 'localhost:9092' -FromBeginning -MessageCount 100 -Verbose |
  ConvertFrom-Json |
  Select-Object *, @{Name='Timestamp'; Expression={ ([datetime]$_['TsTicks']).ToLongTimeString() }} |
  Out-KafkaTopic -TopicName 'test_two' -BrokerList 'localhost:9092' -BatchSize 100 -PassThru -Verbose |
  Export-Csv 'test.csv'
```

    ## VERBOSE: /home/donald/dev/pwsh/pskafka/bin/deb/kafkacat -b localhost:9092 -q -u -o beginning -c 100 -e -C -t test
    ## VERBOSE: /home/donald/dev/pwsh/pskafka/bin/deb/kafkacat -b localhost:9092 -t test_two -P -X message.send.max.retries=3,queue.buffering.max.ms=1000,queue.buffering.max.messages=100
