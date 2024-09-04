class ReviewsController < ApplicationController

  TABLE_NAME = 'reviews'

  before_action :session_connection

  def index
    cache_key = "reviews_index"
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
    result = run_selecting_query(TABLE_NAME, "id = #{params[:id]}")
    result.each do |r|
      @review = r
    end
  end

  def edit
    review_id = Cassandra::Uuid.new(params[:review_id])
    result = run_selecting_query(TABLE_NAME, "id = #{review_id}")
    result.each do |s|
      @to_edit = s
    end
  end

  def update
    review_id = Cassandra::Uuid.new(params[:id])
    book_id = Cassandra::Uuid.new(params[:book_id])
    filled_params = {
      'review' => params[:review],
      'score' => params[:score].to_i,
      'number_of_up_votes' => params[:number_of_up_votes].to_i,
      'book_id' => book_id
    }

    filled_params.each do |key, value|
      if value.present?
        run_update_query(TABLE_NAME, review_id, key, value)
      end
    end
    update_cache
  
    redirect_to review_path(review_id)
  end

  def new
    @books = run_selecting_query("books")
  end

  def create

    book_id = Cassandra::Uuid.new(params[:book_id])
    filled_params = {
      'id' => params[:id],
      'review' => params[:review],
      'score' => params[:score].to_i,
      'number_of_up_votes' => params[:number_of_up_votes].to_i,
      'book_id' => book_id
    }
    run_inserting_query(TABLE_NAME, filled_params)
    update_cache
    redirect_to reviews_path , notice: 'Reviews was successfully created.'
  end

  def destroy
    run_delete_query_by_id(TABLE_NAME, params[:id])
    update_cache
    redirect_to reviews_path, notice: 'Review was successfully deleted.'
  end

  def update_cache
    Rails.cache.delete("authors_summary")
    Rails.cache.delete("top_rated")
    Rails.cache.delete("reviews_index")
  end
  def session_connection
    @session = Cassandra.cluster(hosts: CASSANDRA_CONFIG[:hosts], port: CASSANDRA_CONFIG[:port]).connect('my_keyspace')
  end
end
