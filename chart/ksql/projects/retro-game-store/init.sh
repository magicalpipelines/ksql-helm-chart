# start kafka in the background
echo "Starting Kafka, Zookeeper, and Schema Registry"
confluent local start schema-registry

# pre-create the following topics for our kafka streams topology
declare -a dev_topics=("console_purchases" "game_purchases" "users")
for i in "${dev_topics[@]}"
do
   echo "Creating topic: $i"
   kafka-topics --zookeeper=localhost:2181 --create --topic "$i" --partitions 4 --replication-factor 1
done

# use the data generator for the avro data
echo "generating dummy data"
# populate the users topic using the console producer
kafka-console-producer --broker-list localhost:9092 --property 'parse.key=true' --property 'key.separator=:' --topic users < /etc/ksql/project/users.json
ksql-datagen schema=game_purchase.avro format=avro topic=game_purchases key=user_id maxInterval=5000 iterations=100 &>/dev/null &
ksql-datagen schema=console_purchase.avro format=avro topic=console_purchases key=user_id maxInterval=5000 iterations=100 &>/dev/null &
