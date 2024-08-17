require 'faker'
require "#{Rails.root}/app/controllers/concerns/database_interactions.rb"

include DatabaseInteractions

# Helper methods to generate data

def create_authors
  50.times do
    run_inserting_query('authors', {
      'name' => Faker::Name.first_name,
      'date_of_birth' => Faker::Date.birthday(min_age: 30, max_age: 90).to_s,
      'country_of_origin' => Faker::Lorem.word.capitalize,
      'short_description' => Faker::Lorem.sentence(word_count: 10)
    })
  end
end

def create_books(author_ids)
  300.times do
    run_inserting_query('books', {
      'name' => Faker::Book.title,
      'summary' => Faker::Lorem.paragraph(sentence_count: 3),
      'date_of_publication' => Faker::Date.between(from: '1900-01-01', to: Date.today).to_s,
      'number_of_sales' => rand(1000..100_000),
      'author_id' => Cassandra::Uuid.new(author_ids.sample.to_s)  # Ensure the correct handling of UUID
    })
  end
end

def create_reviews(book_ids)
  book_ids.each do |book_id|
    rand(1..10).times do
      run_inserting_query('reviews', {
        'review' => Faker::Lorem.sentence(word_count: 20),
        'score' => rand(1..5),
        'number_of_up_votes' => rand(0..500),
        'book_id' => Cassandra::Uuid.new(book_id.to_s)
      })
    end
  end
end

def create_sales(book_ids)
  book_ids.each do |book_id|
    (Date.today.year - 5..Date.today.year).each do |year|
      run_inserting_query('sales', {
        'book_id' => Cassandra::Uuid.new(book_id.to_s),
        'year' => year,
        'sales' => rand(1000..20_000)
      })
    end
  end
end

# Execution

# Create authors
puts "Seeding authors..."
create_authors

# Fetch author IDs
author_ids = run_selecting_query('authors').map { |author| author['id'] }

# Create books
puts "Seeding books..."
create_books(author_ids)

# Fetch book IDs
book_ids = run_selecting_query('books').map { |book| book['id'] }

# Create reviews
puts "Seeding reviews..."
create_reviews(book_ids)

# Create sales
puts "Seeding sales..."
create_sales(book_ids)

puts "Seeding completed."