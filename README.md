# fluent-plugin-aliyunoss

[Fluentd](https://fluentd.org/) output plugin to do something.

aliyunoss output plugin buffers event logs in local file and upload it to aliyun oss periodically.
it is support fluentd>=v0.14.10.

## Installation

### RubyGems

```
$ gem install fluent-plugin-aliyunoss
```

### Bundler

Add following line to your Gemfile:

```ruby
gem "fluent-plugin-aliyunoss"
```

And then execute:

```
$ bundle
```

## Configuration

You can generate configuration template:

```
$ fluent-plugin-config-format output aliyunoss
```

ex:

```
<system>
  workers 2
  root_dir /var/log/fluentd
</system>

<source>
  @type http
  @id http_input

  port 8888
  <parse>
    @type json
    keep_time_key true
  </parse>
</source>

<match debug.*>
  @type aliyunoss
  oss_key_id xxx_id
  oss_key_secret xxx_secret
  oss_bucket xxx_bucket
  oss_endpoint xxx_endpoint

  oss_path "project/${tag}/date=%Y-%m-%d/%{host}-worker#{ENV['SERVERENGINE_WORKER_ID']}-%Y%m%d%H%M%S-%{uuid}.gz"
  store_as gz
  <buffer tag,time>
    @type file
    path xxx
    timekey 10
    timekey_wait 10
    timekey_use_utc true
  </buffer>
  <inject>
    time_key fluentd_time
    time_type string
    time_format '%Y-%m-%d %H:%M:%S'
    tag_key fluentd_tag
  </inject>
</match>
```

**If you want to use the storage format of orc, you need to install and configure some tools..**

``` 
in alpine3.8

apk add -U openjdk8-jre
wget https://search.maven.org/remotecontent?filepath=org/apache/orc/orc-tools/1.5.4/orc-tools-1.5.4-uber.jar -O /orc-tools.jar
```

```  
vi /log4j.properties

log4j.rootLogger=FATAL,stdout
log4j.appender.stdout=org.apache.log4j.ConsoleAppender
log4j.appender.stdout.layout=org.apache.log4j.PatternLayout
log4j.appender.stdout.layout.ConversionPattern=%d %p [%c] - %m%n
```

## Copyright

* Copyright(c) 2019- junjie
* License
  * Apache License, Version 2.0
