-- Raw tweets, e.g. from the Twitter connector
CREATE STREAM tweets (
  CreatedAt BIGINT,
  Id BIGINT,
  Text VARCHAR,
  Source VARCHAR,
  GeoLocation VARCHAR,
  User STRUCT<Id BIGINT, Name VARCHAR, Description VARCHAR, ScreenName VARCHAR, URL VARCHAR, FollowersCount BIGINT, FriendsCount BIGINT>
)
WITH (kafka_topic='tweets', value_format='JSON');

-- Restructure the original data
CREATE STREAM tweets_formatted
WITH (kafka_topic='tweets-formatted') AS
SELECT
  TIMESTAMPTOSTRING(CreatedAt, 'yyyy-MM-dd HH:mm:ss z') as created_at,
  Id as tweet_id,
  Text as tweet_text,
  IFNULL(Source, '') as source,
  IFNULL(GeoLocation, '') as geo_location,
  User->Id as user_id,
  IFNULL(User->Name, '') as user_name,
  IFNULL(User->Description, '') as user_description,
  IFNULL(User->ScreenName, '') as user_screenname,
  IFNULL(User->URL, '') as user_url,
  User->FollowersCount as user_followers_count,
  User->FriendsCount as user_friends_count
FROM tweets ;

-- Filter the above stream and create a new stream related to billing issues
CREATE STREAM tweets_billing
WITH (kafka_topic='tweets-billing') AS
SELECT
  user_name,
  tweet_text
FROM tweets_formatted
WHERE LCASE(tweet_text)
LIKE '%billing%' ;