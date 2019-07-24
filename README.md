# ksql-helm-chart
[KSQL][ksql] is a streaming query engine developed by Confluent, which allows us to query Kafka topics in realtime using 
SQL-like syntax. This repository allows us to deploy KSQL instances using Helm charts, by simply adding a project to the 
[chart/ksql/projects/](chart/ksql/projects/),directory and configuring the instance in [values.yaml](chart/ksql/values.yaml). See the example project included in this repo for more details. This code is built on Confluent Platform 5.3.0.


# Prerequisites
- Docker
- A Kubernetes cluster running somewhere (don't have one? try [minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/))
- [Helm](https://github.com/helm/helm#install) (e.g. `brew install kubernetes-helm`)
- A recent build of the include Docker image (simply run `./script/build` after cloning)

# Quick start
Eager to jump to a KSQL CLI and start playing around? Simply follow these instructions to run the default `example` project:

```bash
# build the Docker image
$ ./script/build

# deploy the chart
$ ./script/deploy

# wait for KSQL to come up. you'll see a log that says "Server up and running"
# command format: ./script/logs <project_name>
$ ./script/logs example

# log into the CLI
# command format: ./script/logs <project_name>
$ ./script/ksql-cli example

# clean up
$ ./script/delete
```
[ksql]: https://www.confluent.io/product/ksql/


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
