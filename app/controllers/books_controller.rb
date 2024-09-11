class BooksController < ApplicationController
  TABLE_NAME = 'books'

  before_action :session_connection

  def top_selling
    # Query to fetch all books with their authors
    cache_key = "top_selling"
    @top_selling_books  = Rails.cache.fetch(cache_key, expires_in: 12.hours) do
      books_query = "SELECT * FROM books"
      books = @session.execute(books_query).to_a

      authors_query = "SELECT id, name FROM authors"
      authors = @session.execute(authors_query).to_a
      authors_map = authors.each_with_object({}) { |author, hash| hash[author['id']] = author['name'] }

      sales_query = "SELECT book_id, year, sales FROM sales"
      sales_data = @session.execute(sales_query).to_a


      ## Agrupar las ventas por libro
      sales_by_book = sales_data.group_by { |sale| sale['book_id'] }

      # Calcular el total de ventas para cada libro
      total_sales_by_book = sales_by_book.transform_values { |sales| sales.sum { |sale| sale['sales'] } }


      # Calcular el total de ventas para cada autor
      total_sales_by_author = books.group_by { |book| book['author_id'] }.transform_values do |author_books|
        author_books.sum { |book| total_sales_by_book[book['id']] || 0 }
      end

      @top_selling_books = books.map do |book|
        author_name = authors_map[book['author_id']]
        total_sales = total_sales_by_book[book['id']] || 0
  
        # Verificar si el libro estuvo en el top 5 de ventas en su año de publicación
        publication_year = book['date_of_publication'].year
        sales_in_publication_year = sales_by_book[book['id']]&.select { |sale| sale['year'] == publication_year }&.sum { |sale| sale['sales'] } || 0
  
        # Identificar si estuvo en el top 5
        top_5_in_year = sales_by_book.values.flatten.select { |sale| sale['year'] == publication_year }
                                      .sort_by { |sale| -sale['sales'] }.first(5).any? { |sale| sale['book_id'] == book['id'] }
  
        # Calcular el total de ventas para el autor
        total_author_sales = total_sales_by_author[book['author_id']] || 0

        book.merge(
          'author_name' => author_name,
          'total_sales' => total_sales,
          'total_author_sales' => total_author_sales,
          'top_5_in_year' => top_5_in_year ? "Yes" : "No"
        )
      end
    end
    @top_selling_books = @top_selling_books.sort_by { |book| -book['total_sales'] }.first(50)
  end

  def top_rated
    cache_key = "top_rated"
    @top_books = Rails.cache.fetch(cache_key, expires_in: 12.hours) do
      # Query to fetch all books
      query = "SELECT id, name FROM books"
      books = @session.execute(query).to_a
      @top_books = books.map do |book|
        book_id = book['id']
        # Calculate average rating
        avg_score = @session.execute("SELECT AVG(score) FROM reviews WHERE book_id = ? ALLOW FILTERING", arguments: [book_id]).first['system.avg(score)']

        # Fetch all reviews for the book
        reviews = @session.execute("SELECT * FROM reviews WHERE book_id = ? ALLOW FILTERING", arguments: [book_id]).to_a

        # Find the highest and lowest upvoted reviews
        highest_review = reviews.max_by { |review| review['number_of_up_votes'] }
        lowest_review = reviews.min_by { |review| review['number_of_up_votes'] }

        book.merge(
          'avg_score' => avg_score,
          'highest_review' => highest_review,
          'lowest_review' => lowest_review
        )
      end
    end
    @top_books =  @top_books.sort_by { |book| -book['avg_score'] }.first(10)
    
  end

  def search
    
    if params[:query].present?
      search_terms = params[:query]
      if ElasticsearchService.connected?
        elasticsearch_query = ElasticsearchService.query( 'summary', search_terms)
        elasticsearch_results = ElasticsearchService.search('books', elasticsearch_query)
        @books = elasticsearch_results['hits']['hits'].any? ? elasticsearch_results['hits']['hits'].map { |hit| hit['_source'] } : []
      else
        @books = []
      end
      if @books.empty?
        cache_key = "books_index"
        # Intentar leer la caché
        cached_result = Rails.cache.read(cache_key)
        all_books = cached_result.present? ? cached_result : run_selecting_query(TABLE_NAME).map(&:to_h)
        # Cache if the result isn't empty
        @books = all_books.select do |book|
          book['summary'].downcase.include?(search_terms.downcase)
        end
      else
        @books.each do |book|
          book['author_id'] = Cassandra::Uuid.new(book['author_id'])
        end
      end

      per_page = 10
      page = params[:page].to_i > 0 ? params[:page].to_i : 1
      total_books = @books.size
      @books = @books.slice((page - 1) * per_page, per_page) || []

      @total_pages = (total_books / per_page.to_f).ceil
      @current_page = page

      author_ids = @books.map { |book| book['author_id'] }.uniq

      authors = []
      author_ids.each do |author_id|
        author_query = "SELECT id, name FROM authors WHERE id = ?"
        
        # Ensure author_id is a UUID object, whether it's a string or already a UUID
        uuid_author_id = author_id.is_a?(Cassandra::Uuid) ? author_id : Cassandra::Uuid.new(author_id)
        
        begin
          author = @session.execute(author_query, arguments: [uuid_author_id]).first
        rescue => e
          puts "Error executing query: #{e.message}"
        end
        authors << author if author
      end
      

      @authors_map = authors.each_with_object({}) do |author, hash|
        hash[author['id']] = author['name']
      end
    else
      @books = []
      @total_pages = 0
      @current_page = 0
    end
  end

  def index
    cache_key = "books_index"
    # Intentar leer la caché
    cached_result = Rails.cache.read(cache_key)
    if cached_result.present?
      @results = cached_result
    else
      query_result = run_selecting_query(TABLE_NAME)
      serializable_result = query_result.map(&:to_h)
      # Guardar el resultado serializable en la caché si no está vacío
      if serializable_result.present?
        Rails.cache.write(cache_key, serializable_result, expires_in: 12.hours)
      end
      @results = serializable_result
    end

  end

  def show
    cache_key= "books_show/#{params[:id]}"
    cached_result = Rails.cache.read(cache_key)
    if cached_result.present?
      result = cached_result
    else
      result = run_selecting_query(TABLE_NAME, "id = #{params[:id]}")
      serializable_result = result.map(&:to_h)
      # Guardar el resultado serializable en la caché si no está vacío
      if serializable_result.present?
        Rails.cache.write(cache_key, serializable_result, expires_in: 12.hours)
      end
    end
    result.each do |b|
      @book = b
    end
  end

  def edit
    cache_key = "books_show/#{params[:book_id]}"
    cached_result = Rails.cache.read(cache_key)
    if cached_result.present?
      @to_edit = cached_result.first
    else
      book_id = Cassandra::Uuid.new(params[:book_id])
      result = run_selecting_query(TABLE_NAME, "id = #{book_id}")
      # Guardar el resultado serializable en la caché si no está vacío
      Rails.cache.write(cache_key, result.to_a, expires_in: 12.hours)
      @to_edit = result.first
    end
  end
  

  def update
    book_id = Cassandra::Uuid.new(params[:id])
    author_id = Cassandra::Uuid.new(params[:author_id])
  
    # Prepare the data for Cassandra
    filled_params = {
      'name' => params[:name],
      'summary' => params[:summary],
      'date_of_publication' => params[:date_of_publication],
      'number_of_sales' => params[:number_of_sales].to_i,
      'author_id' => author_id
    }
  
    # Update Cassandra database
    filled_params.each do |key, value|
      if value.present?
        run_update_query(TABLE_NAME, book_id, key, value)
      end
    end
    # Transform data for Elasticsearch
    es_data = filled_params.transform_values do |v|
      v.is_a?(Cassandra::Uuid) ? v.to_s : v
    end

    Rails.logger.debug("Updating Elasticsearch document with ID: #{book_id.to_s}")
    Rails.logger.debug("Elasticsearch document data: #{es_data.inspect}")

    # Update Elasticsearch document
    begin
      ElasticsearchClient.update_document(TABLE_NAME, book_id.to_s, es_data)
    rescue => e
      Rails.logger.error("Failed to update Elasticsearch document: #{e.message}")
    end
 
    update_cache
    redirect_to book_path(book_id), notice: 'Book was successfully updated.'

  end
  

  def new
    # Obtener todos los autores
    @authors = run_selecting_query("authors")
    
  end

  def create
    author_id = Cassandra::Uuid.new(params[:author_id])
    book_id = Cassandra::Uuid.new(params[:id])
   
    filled_params = {
      'id' => params[:id],
      'name' => params[:name],
      'summary' => params[:summary],
      'date_of_publication' => params[:date_of_publication],
      'number_of_sales' => 0,
      'author_id' => author_id
    }
    
    run_inserting_query(TABLE_NAME, filled_params)

    es_data = filled_params.transform_values do |v|
      v.is_a?(Cassandra::Uuid) ? v.to_s : v
    end

    Rails.logger.debug("Creating Elasticsearch document with ID: #{book_id.to_s}")
    Rails.logger.debug("Elasticsearch document data: #{es_data.inspect}")
    
    begin
      ElasticsearchClient.index_document(TABLE_NAME, es_data['id'], es_data)
    rescue => e
      Rails.logger.error("Failed to index Elasticsearch document: #{e.message}")
    end
 
    update_cache
    # Redireccionar al índice de libros después de crear
    redirect_to books_path, notice: 'Book was successfully created.'
  end
  


  def destroy
    run_delete_query_by_id(TABLE_NAME, params[:id])


    # Delete document from Elasticsearch
    begin
      ElasticsearchClient.delete_document(TABLE_NAME, params[:id])
    rescue => e
      Rails.logger.error("Failed to delete Elasticsearch document: #{e.message}")
    end
    update_cache
    redirect_to books_path, notice: 'Book was successfully deleted.'
  end

  def update_cache
    Rails.cache.delete("books_show/#{params[:id]}")
    Rails.cache.delete("books_index")
    Rails.cache.delete("top_rated")
    Rails.cache.delete("top_selling")
  end

  def session_connection
    @session = Cassandra.cluster(hosts: CASSANDRA_CONFIG[:hosts], port: CASSANDRA_CONFIG[:port]).connect('my_keyspace')
  end
end
