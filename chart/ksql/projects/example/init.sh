# start kafka in the background
echo "Running local instance of Kafka"
confluent local start kafka

# pre-create the following topics for our kafka streams topology
declare -a dev_topics=("tweets")
for i in "${dev_topics[@]}"
do
   echo "Creating topic: $i"
   kafka-topics --zookeeper=localhost:2181 --create --topic "$i" --partitions 4 --replication-factor 1
done

# throw some dummy data into the tweets topic
echo "Writing data to tweets topic"
kafka-console-producer --broker-list localhost:9092 --topic tweets < /etc/ksql/project/twitter.json