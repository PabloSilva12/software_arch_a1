class ElasticsearchService
    def initialize
      @client = Elasticsearch::Model.client
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
  