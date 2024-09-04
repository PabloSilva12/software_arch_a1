class AuthorsController < ApplicationController

  TABLE_NAME = 'authors'

  before_action :session_connection

  def author_summary
    # Implementación del cache
    cache_key = "authors_summary"
    @results = Rails.cache.fetch(cache_key, expires_in: 12.hours) do
      query = "SELECT id, name FROM authors"
      authors = @session.execute(query).to_a
    
      authors.map do |author|
        author_id = author['id']
    
        # Fetch books for the author
        books = @session.execute(
          "SELECT id FROM books WHERE author_id = ? ALLOW FILTERING", arguments: [author_id]
        ).to_a
    
        # Initialize counters
        books_count = books.size
        total_sales = 0
        total_score = 0
        total_reviews = 0
    
        books.each do |book|
          book_id = book['id']
    
          # Calculate average score
          review_query = "SELECT score FROM reviews WHERE book_id = ? ALLOW FILTERING"
          reviews = @session.execute(review_query, arguments: [book_id]).to_a
          total_reviews += reviews.size
          reviews.each do |review|
            total_score += review['score']
          end
    
          # Calculate total sales
          sales_query = "SELECT sales FROM sales WHERE book_id = ? ALLOW FILTERING"
          sales = @session.execute(sales_query, arguments: [book_id]).to_a
          sales.each do |sale|
            total_sales += sale['sales']
          end
        end
    
        # Compute average score
        average_score = total_reviews > 0 ? total_score.to_f / total_reviews : 0
        # Merge results
        author.merge('books_count' => books_count, 'average_score' => average_score, 'total_sales' => total_sales)
      end
    end
    # Handle sorting
    if params[:sort_by]
      sort_order = params[:sort_order] == 'desc' ? 'desc' : 'asc'
      @results.sort_by! { |author| author[params[:sort_by]].to_s }
      @results.reverse! if sort_order == 'desc'
    end
  
    # Apply filtering
    if params[:filter_by] && params[:filter_value]
      @results.select! { |author| author[params[:filter_by]].to_s.include?(params[:filter_value]) }
    end
  end

  def index
    cache_key = "authors_index"

    # Intentar leer la caché
    cached_result = Rails.cache.read(cache_key)
    
    if cached_result.present?
      # Si hay datos en la caché, parsearlos
      @results = cached_result
    else
      # Si no hay caché, ejecutar la consulta
      query_result = run_selecting_query(TABLE_NAME)
      # Convertir el resultado en un array de hashes, que es serializable
      serializable_result = query_result.map(&:to_h)
      # Guardar el resultado serializable en la caché si no está vacío
      if serializable_result.present?
        Rails.cache.write(cache_key, serializable_result, expires_in: 12.hours)
      end
      
      # Asignar los resultados a @results
      @results = serializable_result
    end
    
    # En caso de que no haya datos, asegurar que @results no sea nil
    @results ||= []
  end
  
  
  

  def show
    cache_key= "authors_show/#{params[:id]}"
    if Rails.cache.read(cache_key).present?
      @results = Rails.cache.read(cache_key)
      @results.each do |a|
        @author = a
      end
    else
      @results = run_selecting_query(TABLE_NAME, "id = #{params[:id]}")
      @results.each do |a|
        @author = a
      end
      serializable_result = @results.map(&:to_h)
      # Guardar el resultado serializable en la caché si no está vacío
      if serializable_result.present?
        Rails.cache.write(cache_key, serializable_result, expires_in: 12.hours)
      end
    end
  end

  def edit
    cache_key = "authors_show/#{params[:author_id]}"
    # Intentar leer la caché
    cached_result = Rails.cache.read(cache_key)
    
    if cached_result.present?
      @to_edit = cached_result.first
    else
      # Convertir el author_id a UUID usando el parámetro correcto
      author_id = Cassandra::Uuid.new(params[:author_id])
      # Ejecutar la consulta con el UUID
      result = run_selecting_query(TABLE_NAME, "id = #{author_id}")
      
      # Guardar el resultado en caché
      Rails.cache.write(cache_key, result.to_a, expires_in: 12.hours) if result.present?
      
      @to_edit = result.first
    end
  end
  
  

  def update
    author_id = Cassandra::Uuid.new(params[:id])
  
    filled_params = {
      'name' => params[:name],
      'date_of_birth' => params[:date_of_birth],
      'country_of_origin' => params[:country_of_origin],
      'short_description' => params[:short_description]
    }
  
    filled_params.each do |key, value|
      if value.present?
        run_update_query(TABLE_NAME, author_id, key, value)
      end
    end
    update_cache
    
    redirect_to author_path(author_id)
  end
  
  def update_cache
    Rails.cache.delete("authors_show/#{params[:id]}")
    Rails.cache.delete("authors_index")
    Rails.cache.delete("authors_summary")
  end

  def new
  end

  def create
    # Obteniendo los parámetros directamente
    filled_params = {
      'id' => params[:id],
      'name' => params[:name],
      'date_of_birth' => params[:date_of_birth],
      'country_of_origin' => params[:country_of_origin],
      'short_description' => params[:short_description]
    }
  
    # Insertando en la base de datos
    run_inserting_query(TABLE_NAME, filled_params)
    update_cache

    # Redireccionar al índice de autores después de crear
    redirect_to authors_path, notice: 'Author was successfully created.'
  end

  def destroy
    run_delete_query_by_id(TABLE_NAME, params[:id])
    redirect_to authors_path, notice: "Author was deleted."
    update_cache
  end
  
  def session_connection
    @session = Cassandra.cluster(hosts: CASSANDRA_CONFIG[:hosts], port: CASSANDRA_CONFIG[:port]).connect('my_keyspace')
  end
end
