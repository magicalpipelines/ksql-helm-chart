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

# use the data generator
echo "generating dummy data in the background"
ksql-datagen schema=tweet.avro format=json topic=tweets key=Id maxInterval=5000 iterations=100 &>/dev/null &