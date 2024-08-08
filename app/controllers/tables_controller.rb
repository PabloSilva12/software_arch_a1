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
      puts rows
      rows.each do |row|
        puts "espacio1: #{row[0]} espacio2: #{row[1]}"
      end
    end
  end
end
