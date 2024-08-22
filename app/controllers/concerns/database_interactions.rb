require 'cassandra'
module DatabaseInteractions

  extend ActiveSupport::Concern

  KEYSPACE = 'my_keyspace'
  COLUMNS_BY_TABLE = {
    'authors' => ['id', 'name', 'date_of_birth', 'country_of_origin', 'short_description'],
    'books' => ['id', 'name', 'summary', 'date_of_publication', 'number_of_sales', 'author_id'],
    'reviews' => ['id', 'review', 'score', 'number_of_up_votes', 'book_id' ],
    'sales' => ['id', 'book_id', 'year', 'sales']
  }

  def run_inserting_query(table_name, parameters)
    cluster = Cassandra.cluster(
      hosts: CASSANDRA_CONFIG[:hosts],
      port: CASSANDRA_CONFIG[:port]
    )
    session = cluster.connect(KEYSPACE)
    base_parameters = COLUMNS_BY_TABLE[table_name]
    columns = []
    values = []
  
    base_parameters.each_with_index do |column, index|
      next if index == 0  # Skip 'id' column, it's generated by UUID()
  
      value = parameters[column]
      columns << column
      # Handle UUIDs properly
      if value.is_a?(Cassandra::Uuid)
        values << value.to_s  # Convert UUID to string format
      elsif value.is_a?(Integer) || value.is_a?(Float)
        values << value.to_s  # Convert numbers to strings
      else
        values << "'#{value.gsub("'", "''")}'"  # Handle strings, escaping single quotes
      end
    end
    columns_string = columns.join(', ')
    values_string = values.join(', ')
    query = "INSERT INTO #{KEYSPACE}.#{table_name} (id, #{columns_string}) VALUES (uuid(), #{values_string});"
  
    puts query  # For debugging
    session.execute(query)
  end

  def run_selecting_query(table_name, filter = 'FALSE')
    cluster = Cassandra.cluster(
      hosts: CASSANDRA_CONFIG[:hosts],
      port: CASSANDRA_CONFIG[:port]
    )
    session  = cluster.connect(KEYSPACE)
    query = if filter == 'FALSE'
      "SELECT * FROM #{KEYSPACE}.#{table_name};"
    else
      "SELECT * FROM #{KEYSPACE}.#{table_name} WHERE #{filter};"
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
    
    # Asegurarse de que los valores de texto estén entre comillas simples
    value = "'#{value}'" if value.is_a?(String) 
    # Construir la consulta de actualización correctamente
    query = "UPDATE #{KEYSPACE}.#{table_name} SET #{parameter} = #{value} WHERE id = #{id}"
    
    # Ejecutar la consulta
    session.execute(query)
  end
  
end
