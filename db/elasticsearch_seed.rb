require "#{Rails.root}/app/services/elasticsearch_service.rb" 
require "#{Rails.root}/app/controllers/concerns/database_interactions.rb"
include DatabaseInteractions
def create_reviews_index
  ElasticsearchService.create_index(ElasticsearchService::INDEXES[:reviews], ElasticsearchService.reviews_mapping)
end
def create_books_index
  ElasticsearchService.create_index(ElasticsearchService::INDEXES[:books], ElasticsearchService.books_mapping)
end
def create_authors_index
  ElasticsearchService.create_index(ElasticsearchService::INDEXES[:authors], ElasticsearchService.authors_mapping)
end
def create_authors_summary_index
  ElasticsearchService.create_index(ElasticsearchService::INDEXES[:author_summary], ElasticsearchService.author_summary_mapping)
end
def index_authors_in_elasticsearch
  create_authors_index
  @authors = run_selecting_query("authors")
  @authors.each do |author|
    new_id = Cassandra::Uuid.new(author["id"]).to_s
    author_json = author.as_json
    author_json["id"] = new_id
    ElasticsearchService.index_document(ElasticsearchService::INDEXES[:authors], new_id, author_json)
  end
end


def index_books_in_elasticsearch
  create_books_index
  @books = run_selecting_query('books')
    @books.each do |book|
      new_id = Cassandra::Uuid.new(book["id"]).to_s
      author_id = Cassandra::Uuid.new(book["author_id"]).to_s
      book_json = book.as_json
      book_json["id"] = new_id
      book_json["author_id"] = author_id
      ElasticsearchService.index_document(ElasticsearchService::INDEXES[:books], new_id ,book_json)
    end
end

def index_reviews_in_elasticsearch
  create_reviews_index

  @reviews = run_selecting_query("reviews")
  @reviews.each do |review|
    new_id = Cassandra::Uuid.new(review["id"]).to_s
    book_id = Cassandra::Uuid.new(review["book_id"]).to_s
    review_json = review.as_json
    review_json["id"] = new_id
    review_json["book_id"] = book_id
    ElasticsearchService.index_document("reviews", new_id, review_json)
  end
end
create_authors_summary_index
puts " Indexing authors in Elastisearch..."
index_authors_in_elasticsearch
puts "Indexing books in Elasticsearch..."
index_books_in_elasticsearch
puts "Indexing reviews in Elasticsearch..." 
index_reviews_in_elasticsearch
puts "END"

