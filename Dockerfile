FROM magicalpipelines/centos-7-confluent-platform:5.3.0

ADD docker-entrypoint.sh /docker-entrypoint.sh

RUN mkdir -p /etc/ksql/jmxexporter
RUN mkdir -p /opt/ksql/ext

# Prometheus JMX exporter
ARG PROMETHEUS_JMX_EXPORT_VERSION=0.3.1
ADD https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/$PROMETHEUS_JMX_EXPORT_VERSION/jmx_prometheus_javaagent-$PROMETHEUS_JMX_EXPORT_VERSION.jar /opt/ksql/jmx_prometheus_javaagent.jar
ADD files/jmx_exporter_config.yaml /etc/ksql/jmxexporter/jmx_exporter_config.yaml
ENV KSQL_JMX_PORT=1099

# Add custom functions to the extension directory
ADD functions-out/ /opt/ksql/ext/

EXPOSE 8080

# If no command is specified when running this container, just drop the user
# in a bash shell
CMD ["bash"]
ENTRYPOINT ["/docker-entrypoint.sh"]

