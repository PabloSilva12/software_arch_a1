class ReviewsController < ApplicationController

  TABLE_NAME = 'reviews'

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

  end

  def new
  end

  def create
    filled_params = {}
    params[:upd_form].each do |key, value|
      if value.present?
        filled_params[key] = value
      end
    end

    run_inserting_query(TABLE_NAME, filled_params)
  end

  def delete
    run_delete_query_by_id(TABLE_NAME, params[:id])
  end
end

@session = Cassandra.cluster(hosts: CASSANDRA_CONFIG[:hosts], port: CASSANDRA_CONFIG[:port]).connect("keyspace")
