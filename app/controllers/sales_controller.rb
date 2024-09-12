class SalesController < ApplicationController

  TABLE_NAME = 'sales'

  before_action :session_connection
  skip_before_action :verify_authenticity_token

  def index
    cache_key = "sales_index"
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
    @results ||= []
  end

  def show
    result = run_selecting_query(TABLE_NAME, "id = #{params[:id]}")
    result.each do |s|
      @sale = s
    end
  end

  def edit
    @id = Cassandra::Uuid.new(params[:sale_id])
    result = run_selecting_query(TABLE_NAME, "id = #{@id}")
    result.each do |s|
      @sale = s
    end
  end

  def update
    sales_id = Cassandra::Uuid.new(params[:id])
    book_id = Cassandra::Uuid.new(params[:book_id])
    filled_params = {
      'book_id' => book_id,
      'year' => params[:year].to_i,
      'sales' => params[:sales].to_i
    }
    filled_params.each do |key, value|
      if value.present?
        run_update_query(TABLE_NAME, sales_id, key, value)
      end
    end
    update_number_of_sales(book_id)
    update_cache
    redirect_to sales_path(sales_id)
  end

  def update_number_of_sales(book_id)
    # Contar el número total de ventas para el libro dado
    sales_count_query = "SELECT COUNT(*) FROM my_keyspace.sales WHERE book_id = ? ALLOW FILTERING"
    total_sales = @session.execute(sales_count_query, arguments: [book_id]).first['count']
  
    # Actualizar el campo number_of_sales en la tabla books usando run_update_query
    run_update_query('books', book_id, 'number_of_sales', total_sales)
  end
  
  
  def new
    @books = run_selecting_query("books")
  end

  def create
    book_id = Cassandra::Uuid.new(params[:book_id])
    filled_params = {
      'id' => params[:id],
      'book_id' => book_id,
      'year' => params[:year].to_i,
      'sales' => params[:sales].to_i
    }
    run_inserting_query(TABLE_NAME, filled_params)
    update_number_of_sales(book_id)
    update_cache
    redirect_to sales_path, notice: 'Sale was successfully created.'
  end

  def destroy
    # Step 1: Query Cassandra to get the sale record using the sale ID
    sale_id = params[:id].to_s
    sale_record = run_selecting_query(TABLE_NAME, "id = #{sale_id}").first
    
    if sale_record.present?
      # Step 2: Extract the book_id from the sale record
      book_id = sale_record['book_id']
      
      # Step 3: Update the number of sales for the book
      update_number_of_sales(book_id)
      
      # Step 4: Proceed with deleting the sale
      run_delete_query_by_id(TABLE_NAME, sale_id)
      
      # Step 5: Update the cache
      update_cache
      
      # Step 6: Redirect with a success message
      redirect_to sales_path, notice: 'Sale was successfully deleted.'
    else
      # Handle case where sale record is not found
      redirect_to sales_path, alert: 'Sale not found.'
    end
  end
  
  def update_cache
    Rails.cache.delete("authors_summary")
    Rails.cache.delete("sales_index")
    Rails.cache.delete("books_index")
    Rails.cache.delete("top_selling")
  end

  def session_connection
    @session = Cassandra.cluster(hosts: CASSANDRA_CONFIG[:hosts], port: CASSANDRA_CONFIG[:port]).connect('my_keyspace')
  end
end
