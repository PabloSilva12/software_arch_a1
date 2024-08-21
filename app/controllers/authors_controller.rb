class AuthorsController < ApplicationController

  TABLE_NAME = 'authors'

  before_action :session_connection
  
  def author_summary
    session_connection
    query = "SELECT id, name FROM authors"
    authors = @session.execute(query).to_a
  
    @results = authors.map do |author|
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
  
    # Apply sorting and filtering if provided
    @results.sort_by! { |author| author[params[:sort_by]] } if params[:sort_by]
    @results.select! { |author| author[params[:filter_by]].to_s.include?(params[:filter_value]) } if params[:filter_by]
  end
  
  

  def index
    @results = run_selecting_query(TABLE_NAME)
  end

  def show
    result = run_selecting_query(TABLE_NAME, "id = #{params[:id]}")
    result.each do |a|
      @author = a
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

  def destroy
    run_delete_query_by_id(TABLE_NAME, params[:id])
  end
  def session_connection
    @session = Cassandra.cluster(hosts: CASSANDRA_CONFIG[:hosts], port: CASSANDRA_CONFIG[:port]).connect('my_keyspace')
  end
end
