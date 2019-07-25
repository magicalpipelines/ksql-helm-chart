-- Show schemas
-- *.avro

-- show datagen
-- ksql-datagen schema=game_purchase.avro format=json topic=game_purchases key=user_id maxInterval=5000 iterations=100 &>/dev/null &
-- ksql-datagen schema=console_purchase.avro format=json topic=console_purchases key=user_id maxInterval=5000 iterations=100 &>/dev/null &

-- create USERS table from `users` topic

CREATE TABLE users(
  user_id VARCHAR,
  first_name VARCHAR,
  last_name VARCHAR,
  email VARCHAR,
  address STRUCT<street VARCHAR, city VARCHAR, state VARCHAR, zip INT>)
WITH (
  kafka_topic='users',
  value_format='json',
  key='user_id'
);
-- SELECT * FROM users ;

-- Create streams for the other topics. Show registered field
-- NOte: the underlying data is Avro-encoded, so we don't need to define fields!
CREATE STREAM game_purchases
WITH (
  kafka_topic='game_purchases',
  value_format='avro'
);

CREATE STREAM console_purchases
WITH (
  kafka_topic='console_purchases',
  value_format='avro'
);

-- Combine the streams
-- CSAS
CREATE STREAM all_purchases
WITH (
  kafka_topic='purchases',
  value_format='avro'
) AS
SELECT * FROM game_purchases ;

INSERT INTO all_purchases SELECT * FROM all_purchases;

-- Join the users stream
/*
SELECT 
  u.user_id, u.first_name,
  u.last_name,
  p.purchase_id,
  p.product,
  p.product_type,
  p.credit_card
FROM all_purchases p
LEFT JOIN users u
ON p.user_id = u.user_id
LIMIT 3;

-- Concatenate fields
SELECT
  u.user_id,
  u.first_name || ' ' || u.last_name as full_name,
  p.purchase_id,
  p.product,
  p.product_type,
  p.credit_card
FROM all_purchases p
LEFT JOIN users u
ON p.user_id = u.user_id
LIMIT 3;

-- DESCRIBE FUNCTION mask_left ;
-- Mask fields
SELECT
  u.user_id,
  u.first_name || ' ' || u.last_name as full_name,
  p.purchase_id,
  p.product,
  p.product_type,
  MASK_LEFT(p.credit_card, 15, 'x', 'x', 'x', '-')
FROM all_purchases p
LEFT JOIN users u
ON p.user_id = u.user_id
LIMIT 3;
*/
-- Reformat to JSON
CREATE STREAM purchases_reformatted
WITH (
  kafka_topic='purchases',
  value_format='avro'
) AS
SELECT
  u.user_id as user_id,
  u.first_name || ' ' || u.last_name as full_name,
  p.purchase_id as purchase_id,
  p.product as product,
  p.product_type as product_type,
  MASK_LEFT(p.credit_card, 15, 'x', 'x', 'x', '-') as masked_credit_card 
FROM all_purchases p
LEFT JOIN users u
ON p.user_id = u.user_id;
-- DESCRIBE purchases_reformatted ;
-- SELECT * FROM purchases_reformatted ;

-- Demonstrate windowing to catch suspicious transactions
CREATE TABLE suspicious_transactions
WITH (
  kafka_topic='suspicious_transactions',
  value_format='avro'
) AS
SELECT
  p.user_id,
  p.masked_credit_card,
  COUNT() as total_purchases
FROM purchases_reformatted p
WINDOW TUMBLING (SIZE 10 SECONDS)
GROUP BY
  p.user_id,
  p.masked_credit_card
HAVING COUNT() > 3 ;
-- SELECT user_id, masked_credit_card, total_purchases FROM suspicious_transactions LIMIT 1 ;