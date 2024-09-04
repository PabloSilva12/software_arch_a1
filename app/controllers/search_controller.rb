class SearchController < ApplicationController
    def search
      query = {
        query: {
          multi_match: {
            query: params[:q],
            fields: ['title', 'summary', 'content']
          }
        }
      }
  
      books_results = ElasticsearchClient.search('books', query)
      reviews_results = ElasticsearchClient.search('reviews', query)
  
      render json: { books: books_results['hits']['hits'], reviews: reviews_results['hits']['hits'] }
    end
  end
  