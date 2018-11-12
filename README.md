# ksql-helm-chart
[KSQL][ksql] is a streaming query engine developed by Confluent, which allows us to query Kafka topics in realtime using 
SQL-like syntax. This repository allows us to deploy KSQL queries as a Helm chart, by simply adding a query to the 
[queries configmap](chart/ksql/templates/configmap-ksql-queries.yaml), and configuring a KSQL
instance in [values.yaml](chart/ksql/values.yaml). This code is built on Confluent Platform 5.0.0.


# Prerequisites
- Docker
- A Kubernetes cluster running somewhere (don't have one? try [minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/))
- [Helm](https://github.com/helm/helm#install) (e.g. `brew install kubernetes-helm`)
- A recent build of the include Docker image (simply run `./script/build` after cloning)

# Quick start
Eager to jump to a KSQL CLI and start playing around? Simply follow these instructions:

```bash
# build the Docker image
$ ./script/build

# deploy the chart
$ ./script/deploy

# log into the KSQL CLI
$ kubectl exec -ti <YOUR_KSQL_POD_NAME> ksql

# clean up
$ ./script/delete
```
[ksql]: https://www.confluent.io/product/ksql/

# Modes
You can run KSQL in one of two modes: interactive or headless. Each mode is described in more detail below.


## Interactive
Running KSQL in interactive mode is good for sandboxing and experimentation because it allows you to test your queries using the KSQL CLI.

To run KSQL in interactive mode, configure the following parameters for your KSQL instance in `values.yaml`:
- `runKafkaLocally`: Any non-empty string will result in a local Kafka cluster being started
- `createDevSourceTopic`: The name of the source topic you'll be reading from. This topic will be created automatically if set

__Note:__ Setting these configs will run a local Kafka cluster in the same pod as KSQL. This makes it easy to play around 
with KSQL locally.


## Headless
Running KSQL in headless mode disables client access to the KSQL server. This is ideal for prod deployments, or for local 
deployments that should run a query from a pre-defined SQL file (saved in the 
[configmap here](chart/ksql/templates/configmap-ksql-queries.yaml)).

To run in headless, define your query in `chart/ksql/templates/configmap-ksql-queries.yaml` (an example query is already
included). The queries you define in this file will be mounted at the following path in the pod: `/ksql-queries`. Once
you've defined your query, update the `queriesFile` parameter in `values.yaml` with the correct path. For example:

```yaml
ksqlInstances:
    - name: tweets-ksql-prod
      bootstrapServers: "localhost:9092"
      queriesFile: "/ksql-queries/tweets.sql"
      ksqlOpts: "-Dksql.streams.auto.offset.reset=earliest -Dksql.streams.num.stream.threads=4 -Dksql.sink.partitions=4 -Dksql.sink.replicas=1 -Dksql.service.id=dev"
      cpu: 2
      memory: 1Gi
```

## Producing to a local Kafka cluster
Once the pods are running, you'll probably want to test your SQL. Here's an example workflow for how to produce sample 
messages into your local source topic, and make sure the output topic contains the expected results:

```bash
# Log into the appropriate pod
$ kubectl exec -it <YOUR_KSQL_POD_NAME> bash

# Ensure your dev topic (see `createDevSourceTopic`) was created
$ kafka-topics --zookeeper localhost:2181 --list

# Produce some dummy messages. See the hint below this code snippet
$ kafka-console-producer --broker-list localhost:9092 --topic <SOURCE_TOPIC>

# Exit out of the producer, and start the consumer
$ kafka-console-consumer --bootstrap-server localhost:9092 --topic <OUTPUT_TOPIC> --from-beginning

# Verify the output
```

__Hint:__ you may want to use kafkacat to pull an actual message from prod when testing your KSQL queries. [See my article
on mitchseymour.com](http://blog.mitchseymour.com/favorite-kafkacat-cmds/) (under __Poor Man's Mirrormaker__) for an example 
of how to do this.
