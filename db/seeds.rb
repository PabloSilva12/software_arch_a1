require 'faker'
require "#{Rails.root}/app/controllers/concerns/database_interactions.rb"


include DatabaseInteractions

# Helper methods to generate data


def create_authors
  author_ids = []
  50.times do
    id = Cassandra::Uuid::Generator.new.now
    author_ids << id
    run_inserting_query('authors', {
      'id' => id,
      'name' => Faker::Name.first_name,
      'date_of_birth' => Faker::Date.birthday(min_age: 30, max_age: 90).to_s,
      'country_of_origin' => Faker::Lorem.word.capitalize,
      'short_description' => Faker::Lorem.sentence(word_count: 10)
    })
  end
  return author_ids
end

def create_books(author_ids)
  book_ids = []
  300.times do
    id= Cassandra::Uuid::Generator.new.now
    book_ids << id
    book_data = {
      'id' => id,
      'name' => Faker::Book.title,
      'summary' => Faker::Lorem.paragraph(sentence_count: 3),
      'date_of_publication' => Faker::Date.between(from: '1900-01-01', to: Date.today).to_s,
      'number_of_sales' => 0,
      'author_id' => Cassandra::Uuid.new(author_ids.sample.to_s)
    }
    run_inserting_query('books', book_data)
  end
  return book_ids
end

def create_reviews(book_ids)
  book_ids.each do |book_id|
    rand(1..5).times do
      review_data = {
        'id' => Cassandra::Uuid::Generator.new.now,
        'review' => Faker::Lorem.sentence(word_count: 20),
        'score' => rand(1..5),
        'number_of_up_votes' => rand(0..500),
        'book_id' => Cassandra::Uuid.new(book_id.to_s)
      }
      run_inserting_query('reviews', review_data)
    end
  end
end

def create_sales(book_ids)
  @session = Cassandra.cluster(hosts: CASSANDRA_CONFIG[:hosts], port: CASSANDRA_CONFIG[:port]).connect('my_keyspace')
  book_ids.each_with_index do |book_id, index|
    (Date.today.year - 2..Date.today.year).each do |year|
      run_inserting_query('sales', {
        'id' => Cassandra::Uuid::Generator.new.now,
        'book_id' => book_id,
        'year' => year,
        'sales' => rand(1000..20_000)
      })
      puts " upating sales from"
      puts "book_id: #{book_id}"
      update_number_of_sales(book_id)
      sleep(0.5) if index % 100 == 0
    end
  end
end
def update_number_of_sales(book_id)
    # Contar el número total de ventas para el libro dado
    sales_count_query = "SELECT COUNT(*) FROM my_keyspace.sales WHERE book_id = ? ALLOW FILTERING"
    total_sales = @session.execute(sales_count_query, arguments: [book_id]).first['count']
    # Actualizar el campo number_of_sales en la tabla books usando run_update_query
    run_update_query('books', book_id, 'number_of_sales', total_sales)
end
# Execution

# Create authors
puts "Seeding authors..."
author_ids = create_authors

# Create books
puts "Seeding books..."
book_ids = create_books(author_ids)

# # Create reviews
puts "Seeding reviews..."
create_reviews(book_ids)

# Create sales

# def get_all_book_ids
#   # Usar run_selecting_query para seleccionar solo los IDs
#   result_set = run_selecting_query('books')

#   # Filtrar solo los IDs de los resultados
#   book_ids = result_set.map { |row| row['id'] }

#   # Retornar el arreglo de IDs
#   book_ids
# end
puts "Seeding sales..."
create_sales(book_ids)

puts "Seeding completed."