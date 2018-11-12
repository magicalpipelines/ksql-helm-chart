#!/bin/env bash

# Create the KSQL server configuration file
if [ -z "$QUERIES_FILE" ]; then
# No query file was specified, so run KSQL in interactive mode
cat <<EOF >/etc/ksql/server.properties
bootstrap.servers=$BOOTSTRAP_SERVERS
listeners=http://localhost:8088
EOF
else
# A query file was specified, so run KSQL in headless mode
cat <<EOF >/etc/ksql/server.properties
bootstrap.servers=$BOOTSTRAP_SERVERS
ksql.queries.file=$QUERIES_FILE
EOF
fi

# Optionally (dev only), run a local Kafka instance.
#
# Note: We do not run this as a separate pod in a local env since KSQL can't make sense
# of the other pod's hostname (even though it's reachable from the KSQL pod)
[ -n "$RUN_KAFKA_LOCALLY" ] && echo "Running local instance of Kafka" && confluent start kafka
[ -n "$CREATE_TOPIC" ] && kafka-topics --zookeeper localhost:2181 --create --topic $CREATE_TOPIC --partitions 4 --replication-factor 1

# Only export the JMX_PORT after Kafka has been (optionally) started. Otherwise, there will be port conflicts
export JMX_PORT="$KSQL_JMX_PORT"
export KSQL_OPTS="$KSQL_OPTS -javaagent:/opt/ksql/jmx_prometheus_javaagent.jar=8080:/opt/ksql/jmxexporter/jmx_exporter_config.yaml"

cat /etc/ksql/server.properties

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
