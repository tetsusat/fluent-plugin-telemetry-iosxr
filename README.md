# fluent-plugin-telemetry-iosxr, a plugin for [Fluentd](http://fluentd.org)

[Fluentd](http://fluentd.org) input plugin to collect IOS-XR telemetry.

## Requirements

`fluent-plugin-telemetry-iosxr` supports fluentd-0.14.0 or later. 

## installation

    $ fluent-gem install fluent-plugin-telemetry-iosxr

## Usage

### Configuration Example 1

Collect telemetry input and then output to stdout.

```
<source>
  @type telemetry_iosxr
  bind 0.0.0.0
  port 5432
  @label @telemetry
</source>

<label @telemetry>
  <match **>
    @type stdout
  </match>
</label>
```

### Configuration Example 2

Collect telemetry input and then output to InfluxDB with deleting nested input.

```
<source>
  @type telemetry_iosxr
  bind 0.0.0.0
  port 5432
  delete_nested true
  @label @telemetry
</source>

<label @telemetry>
  <match **>
    @type influxdb
    host localhost
    port 8086
    dbname telemetry
    user admin
    password admin
    time_precision s
    auto_tags true
  </match>
</label>
```

**bind**

IP address on which the plugin will accept Telemetry.  
(Default: '0.0.0.0')

**port**

TCP port number on which the plugin will accept Telemetry.  
(Default: 5432)

**delete_nested**

Delete nested input. 
(Default: false)

Assume the input is multi-dimensional as below:

```
{ 
    "node-name":"0/RP0/CPU0",
    "total-cpu-one-minute":2,
    "total-cpu-five-minute":2,
    "total-cpu-fifteen-minute":2,
    "process-cpu":[ 
        { 
            "process-name":"init",
            "process-id":1,
            "process-cpu-one-minute":0,
            "process-cpu-five-minute":0,
            "process-cpu-fifteen-minute":0
        },
        { 
            "process-name":"bash",
            "process-id":1589,
            "process-cpu-one-minute":0,
            "process-cpu-five-minute":0,
            "process-cpu-fifteen-minute":0
        },
        { 
            "process-name":"sh",
            "process-id":1605,
            "process-cpu-one-minute":0,
            "process-cpu-five-minute":0,
            "process-cpu-fifteen-minute":0
        },
        ...
    ]
}
```

Then the output becomes as below:

```
{ 
    "node-name":"0/RP0/CPU0",
    "total-cpu-one-minute":2,
    "total-cpu-five-minute":2,
    "total-cpu-fifteen-minute":2
}
```

### IOS XR Configuration Example

```
telemetry model-driven
 destination-group destination1
  address-family ipv4 <ip_addr> port <port>
   encoding json
   protocol tcp
  !
 !
 sensor-group sensor1
  sensor-path Cisco-IOS-XR-wdsysmon-fd-oper:system-monitoring/cpu-utilization
  sensor-path Cisco-IOS-XR-nto-misc-oper:memory-summary/nodes/node/summary
  sensor-path Cisco-IOS-XR-infra-statsd-oper:infra-statistics/interfaces/interface/latest/data-rate
  sensor-path Cisco-IOS-XR-infra-statsd-oper:infra-statistics/interfaces/interface/latest/generic-counters
 !
 subscription 1
  sensor-group-id sensor1 sample-interval 1000
  destination-id destination1
 !
!
```
