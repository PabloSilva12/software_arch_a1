class ReviewsController < ApplicationController

  TABLE_NAME = 'reviews'

  before_action :session_connection

  INDEX_NAME = 'reviews'

  def index
    @results = run_selecting_query(TABLE_NAME)
  end

  def show
    result = run_selecting_query(TABLE_NAME, "id = #{params[:id]}")
    result.each do |r|
      @review = r
    end
  end

  def edit
    result = run_selecting_query(TABLE_NAME, "id = #{params[:id]}")
    result.each do |s|
      @to_edit = s
    end
  end

  def update
    filled_params = {}
    params[:upd_form].each do |key, value|
      if value.present?
        filled_params[key] = value
      end
    end

    filled_params.each do |key, value|
      if key != "id"
        run_update_query(TABLE_NAME, params[:id], key, value)
      end
    end

    # Update Elasticsearch document
    begin
      ElasticsearchClient.index_document(INDEX_NAME, params[:id], filled_params)
    rescue => e
      Rails.logger.error("Failed to update Elasticsearch document: #{e.message}")
    end

    redirect_to review_path(params[:id]), notice: 'Review was successfully updated.'
  end

  def new
    @books = run_selecting_query("books")
  end

  def create
    filled_params = {}
    params.each do |key, value|
      if value.present?
        filled_params[key] = convert_to_number(value)
      end
    end
    filled_params["book_id"] = Cassandra::Uuid.new(filled_params["book_id"]) if filled_params["book_id"]

    # Insert into Cassandra
    run_inserting_query(TABLE_NAME, filled_params)

    # Index document in Elasticsearch
    begin
      ElasticsearchClient.index_document(INDEX_NAME, filled_params['id'].to_s, filled_params)
    rescue => e
      Rails.logger.error("Failed to index Elasticsearch document: #{e.message}")
    end

    redirect_to reviews_path, notice: 'Review was successfully created.'
  end

  def destroy
    run_delete_query_by_id(TABLE_NAME, params[:id])

    # Delete document from Elasticsearch
    begin
      ElasticsearchClient.delete_document(INDEX_NAME, params[:id])
    rescue => e
      Rails.logger.error("Failed to delete Elasticsearch document: #{e.message}")
    end

    redirect_to reviews_path, notice: 'Review was successfully deleted.'
  end

  private

  def session_connection
    @session = Cassandra.cluster(hosts: CASSANDRA_CONFIG[:hosts], port: CASSANDRA_CONFIG[:port]).connect('my_keyspace')
  end

  def convert_to_number(value)
    value =~ /\A\d+\z/ ? value.to_i : value
  end
end
