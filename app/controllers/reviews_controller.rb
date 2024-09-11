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
    review_id = Cassandra::Uuid.new(params[:id])
    result = run_selecting_query(TABLE_NAME, "id = #{review_id}")
    result.each do |r|
      @review = r
    end
  end
  

  def edit

    @id = params[:review_id]  # Ensure @id is set from the URL parameters
    @review = run_selecting_query(TABLE_NAME, "id = #{Cassandra::Uuid.new(@id)}").first
    # Handle case when the review is not found
    if @review.nil?
      redirect_to reviews_path, alert: 'Review not found.'
    end
  end
  
  

  def update

    review_id = Cassandra::Uuid.new(params[:id]) # Ensure review_id is a valid UUID
  
    # Prepare the data for Cassandra
    filled_params = {
      'review' => params[:review],
      'score' => params[:score].to_i,
      'number_of_up_votes' => params[:number_of_up_votes].to_i
    }
  
    # Update Cassandra database
    filled_params.each do |key, value|
      run_update_query(TABLE_NAME, review_id, key, value) if value.present?
    end
  
    # Transform data for Elasticsearch
    es_data = filled_params.transform_values(&:to_s)

    # Update Elasticsearch document
    begin
      ElasticsearchService.update_document(TABLE_NAME, review_id.to_s, es_data)
    rescue => e
      Rails.logger.error("Failed to update Elasticsearch document: #{e.message}")
    end
  
    update_cache
    redirect_to review_path(review_id), notice: 'Review was successfully updated.'
  end
  

  def new
    @books = run_selecting_query("books")
  end

  def create

    review_id = Cassandra::Uuid.new(params[:id]) # Generate review UUID
    book_id = Cassandra::Uuid.new(params[:book_id])

    # Prepare the data for Cassandra
    filled_params = {
      'id' => review_id,
      'review' => params[:review],
      'score' => params[:score].to_i,
      'number_of_up_votes' => params[:number_of_up_votes].to_i,
      'book_id' => book_id
    }


    # Insert into Cassandra
    run_inserting_query(TABLE_NAME, filled_params)

    # Index document in Elasticsearch
    es_data = filled_params.transform_values(&:to_s)
    Rails.logger.debug("Creating Elasticsearch document with ID: #{review_id}")
    Rails.logger.debug("Elasticsearch document data: #{es_data.inspect}")

    begin
      ElasticsearchClient.index_document(TABLE_NAME, review_id.to_s, es_data)
    rescue => e
      Rails.logger.error("Failed to index Elasticsearch document: #{e.message}")
    end
    update_cache
    redirect_to reviews_path, notice: 'Review was successfully created.'
  end
  
  def search
    if params[:query].present?
      search_terms = params[:query]
      # Create an Elasticsearch query
      if ElasticsearchService.connected?
        elasticsearch_query = ElasticsearchService.query( 'review', search_terms)
        elasticsearch_results = ElasticsearchService.search('reviews', elasticsearch_query)
        @reviews = elasticsearch_results['hits']['hits'].any? ? elasticsearch_results['hits']['hits'].map { |hit| hit['_source'] } : []
      else
        cache_key = "reviews_index"
        cached_result = Rails.cache.read(cache_key)
        all_reviews = cached_result.present? ? cached_result : run_selecting_query(TABLE_NAME).map(&:to_h)
        puts "No results from Elasticsearch. Falling back to cached results."
        @reviews = all_reviews.select do |review|
          review['review'].downcase.include?(search_terms.downcase)
        end 
      end
    else
      @reviews = []
    end
  
  end

  
  def destroy
    review_id = params[:id]

    run_delete_query_by_id(TABLE_NAME, review_id)

    # Delete document from Elasticsearch
    begin
      ElasticsearchClient.delete_document(TABLE_NAME, review_id)
    rescue => e
      Rails.logger.error("Failed to delete Elasticsearch document: #{e.message}")
    end
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
