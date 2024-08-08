require 'cassandra'
module DatabaseInteractions

  extend ActiveSupport::Concern

  KEYSPACE = 'my_keyspace'
  COLUMNS_BY_TABLE = {
    'authors' => ['id', 'name', 'date_of_birth', 'country_of_origin', 'short_description'],
    'books' => ['id', 'name', 'summary', 'date_of_publication', 'number_of_sales', 'author_id'],
    'reviews' => ['id', 'review', 'score', 'number_of_upvotes', 'book_id' ],
    'sales' => ['id', 'book_id', 'year', 'sales']
  }

  def run_inserting_query(table_name, parameters)
    cluster = Cassandra.cluster(
      hosts: CASSANDRA_CONFIG[:hosts],
      port: CASSANDRA_CONFIG[:port]
    )
    session  = cluster.connect(KEYSPACE)
    base_parameters = COLUMNS_BY_TABLE[table_name]
    string_of_base = ""
    string_of_set = ""
    base_parameters.each_with_index do |column, index|
      string_of_base += column
      string_of_base += ", " unless index == columns.length - 1
      if index != 0
        string_of_set += "'#{parameter[column]}'"
        string_of_set += ", " unless index == columns.length - 1
      end
    end
    query = "INSERT INTO #{KEYSPACE}.#{table_name} (#{string_of_base}) VALUES (uuid(), #{string_of_set});"
    session.execute(query)
  end

  def run_selecting_query(table_name, filter = 'FALSE')
    cluster = Cassandra.cluster(
      hosts: CASSANDRA_CONFIG[:hosts],
      port: CASSANDRA_CONFIG[:port]
    )
    session  = cluster.connect(KEYSPACE)
    if filter == 'FALSE'
      query = "SELECT * FROM #{KEYSPACE}.#{table_name};"
    else
      query = "SELECT * FROM #{KEYSPACE}.#{table_name} WHERE #{filter};"
    end
    return session.execute(query)
  end

  def run_delete_query_by_id(table_name, id)
    cluster = Cassandra.cluster(
      hosts: CASSANDRA_CONFIG[:hosts],
      port: CASSANDRA_CONFIG[:port]
    )
    session  = cluster.connect(KEYSPACE)
    query = "DELETE FROM #{KEYSPACE}.#{table_name} WHERE  id = #{id};"
    session.execute(query)
  end

  def run_update_query(table_name, id, parameter, value)
    cluster = Cassandra.cluster(
      hosts: CASSANDRA_CONFIG[:hosts],
      port: CASSANDRA_CONFIG[:port]
    )
    session  = cluster.connect(KEYSPACE)
    query = "UPDATE FROM #{KEYSPACE}.#{table_name} SET #{parameter} = #{value} WHERE  id = #{id};"
    session.execute(query)
  end
end
