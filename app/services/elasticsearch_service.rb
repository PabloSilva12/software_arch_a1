class ElasticsearchService
  def initialize
    @client = ElasticsearchClient.client
  end

  def index_book(book)
    @client.index(
      index: 'books',
      id: book[:id],
      body: {
        name: book[:name],
        summary: book[:summary]
      }
    )
  end

  def index_review(review)
    @client.index(
      index: 'reviews',
      id: review[:id],
      body: {
        review: review[:review]
      }
    )
  end

  def bulk_index_books(books)
    body = books.flat_map do |book|
      {
        index: {
          _index: 'books',
          _id: book[:id],
          data: {
            name: book[:name],
            summary: book[:summary]
          }
        }
      }
    end
    @client.bulk(body: body)
  end

  def bulk_index_reviews(reviews)
    body = reviews.flat_map do |review|
      {
        index: {
          _index: 'reviews',
          _id: review[:id],
          data: {
            review: review[:review]
          }
        }
      }
    end
    @client.bulk(body: body)
  end

  def search_books(query)
    @client.search(
      index: 'books',
      body: {
        query: {
          multi_match: {
            query: query,
            fields: ['name^10', 'summary']
          }
        }
      }
    )
  end

  def search_reviews(query)
    @client.search(
      index: 'reviews',
      body: {
        query: {
          match: {
            review: query
          }
        }
      }
    )
  end
end
