class ReviewsController < ApplicationController

  TABLE_NAME = 'reviews'
  INDEX_NAME = 'reviews'

  before_action :session_connection

  def index
    @results = run_selecting_query(TABLE_NAME)
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
  
    Rails.logger.debug("Updating Elasticsearch document with ID: #{review_id}")
    Rails.logger.debug("Elasticsearch document data: #{es_data.inspect}")
  
    # Update Elasticsearch document
    begin
      ElasticsearchClient.update_document(INDEX_NAME, review_id.to_s, es_data)
    rescue => e
      Rails.logger.error("Failed to update Elasticsearch document: #{e.message}")
    end
  
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
      ElasticsearchClient.index_document(INDEX_NAME, review_id.to_s, es_data)
    rescue => e
      Rails.logger.error("Failed to index Elasticsearch document: #{e.message}")
    end

    redirect_to reviews_path, notice: 'Review was successfully created.'
  end

  def destroy
    review_id = params[:id]

    run_delete_query_by_id(TABLE_NAME, review_id)

    # Delete document from Elasticsearch
    begin
      ElasticsearchClient.delete_document(INDEX_NAME, review_id)
    rescue => e
      Rails.logger.error("Failed to delete Elasticsearch document: #{e.message}")
    end

    redirect_to reviews_path, notice: 'Review was successfully deleted.'
  end

  private

  def session_connection
    @session = Cassandra.cluster(hosts: CASSANDRA_CONFIG[:hosts], port: CASSANDRA_CONFIG[:port]).connect('my_keyspace')
  end
end
