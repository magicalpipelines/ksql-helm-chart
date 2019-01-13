FROM magicalpipelines/centos-7-confluent-platform:5.0.1

ADD docker-entrypoint.sh /docker-entrypoint.sh

RUN mkdir -p /etc/ksql
RUN mkdir -p /opt/ksql/ext

# Prometheus JMX exporter
ARG PROMETHEUS_JMX_EXPORT_VERSION=0.3.1
ADD https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/$PROMETHEUS_JMX_EXPORT_VERSION/jmx_prometheus_javaagent-$PROMETHEUS_JMX_EXPORT_VERSION.jar /opt/ksql/jmx_prometheus_javaagent.jar
ADD files/jmx_exporter_config.yaml /opt/ksql/jmxexporter/jmx_exporter_config.yaml
ENV KSQL_JMX_PORT=1099

# Add custom functions to the extension directory
ADD functions-out/ /opt/ksql/ext/

# JSON logging
ARG LOG4J_JSONEVENT_LAYOUT_VERSION=1.7
ADD http://repo1.maven.org/maven2/net/logstash/log4j/jsonevent-layout/1.7/jsonevent-layout-$LOG4J_JSONEVENT_LAYOUT_VERSION.jar /opt/confluent-$CONFLUENT_VERSION/share/java/confluent-common/

EXPOSE 8080

# Graalvm
RUN mkdir -p /usr/local/bin/graalvm
RUN curl -s -L https://github.com/oracle/graal/releases/download/vm-1.0.0-rc10/graalvm-ce-1.0.0-rc10-linux-amd64.tar.gz | tar zvx -C /usr/local/bin/graalvm --strip-components 1
ENV JAVA_HOME=/usr/local/bin/graalvm
ENV PATH="${JAVA_HOME}/bin/:${PATH}"

ENV BOOTSTRAP_SERVERS=localhost:9092

# If no command is specified when running this container, just drop the user
# in a bash shell
CMD ["bash"]
ENTRYPOINT ["/docker-entrypoint.sh"]

