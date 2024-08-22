class SalesController < ApplicationController

  TABLE_NAME = 'sales'

  before_action :session_connection

  def index
    @results = run_selecting_query(TABLE_NAME)
  end

  def show
    result = run_selecting_query(TABLE_NAME, "id = #{params[:id]}")
    result.each do |s|
      @sale = s
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
    @books = run_selecting_query("books")
  end

  def create
    filled_params = {}
    params.each do |key, value|
      if value.present?
        filled_params[key] = convert_to_number(value)
      end
    end
    filled_params["book_id"] = Cassandra::Uuid.new(filled_params["book_id"])
    run_inserting_query(TABLE_NAME, filled_params)
    redirect_to sales_path
  end

  def delete
    run_delete_query_by_id(TABLE_NAME, params[:id])
  end
  def destroy
    run_delete_query_by_id(TABLE_NAME, params[:id])
  end
  def session_connection
    @session = Cassandra.cluster(hosts: CASSANDRA_CONFIG[:hosts], port: CASSANDRA_CONFIG[:port]).connect('my_keyspace')
  end
end
