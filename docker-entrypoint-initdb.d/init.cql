CREATE KEYSPACE IF NOT EXISTS my_keyspace
WITH REPLICATION = {
   'class' : 'SimpleStrategy',
   'replication_factor' : 1
};
