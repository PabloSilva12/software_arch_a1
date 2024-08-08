require 'cassandra'
class TablesController < ApplicationController

  def index
    cluster = Cassandra.cluster(
      hosts: CASSANDRA_CONFIG[:hosts],
      port: CASSANDRA_CONFIG[:port]
    )
    keyspace = 'my_keyspace'
    session  = cluster.connect(keyspace)
    session.execute('SELECT * FROM authors').each do |rows|
      puts "The keyspace #{row['keyspace_name']} has a table called #{row['columnfamily_name']}"
    end
  end
end
