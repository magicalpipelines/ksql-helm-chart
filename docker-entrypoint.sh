#!/bin/env bash

[ -n "$INIT_SCRIPT" ] && bash $INIT_SCRIPT

# Only export the JMX_PORT after Kafka has been (optionally) started. Otherwise, there will be port conflicts
export JMX_PORT="$KSQL_JMX_PORT"
export KSQL_OPTS="$KSQL_OPTS -javaagent:/opt/ksql/jmx_prometheus_javaagent.jar=8080:/etc/ksql/jmxexporter/jmx_exporter_config.yaml"

KSQL_PID=0

handleInterrupt() {
  kill "$KSQL_PID"
  wait "$KSQL_PID"
  exit
}

trap "handleInterrupt" SIGHUP SIGINT SIGTERM
"$@" &
KSQL_PID=$!
wait

"$@"
