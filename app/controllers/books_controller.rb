class BooksController < ApplicationController

  TABLE_NAME = 'books'

  before_action :session_connection

  def top_rated
    # Query to fetch all books
    query = "SELECT id, name FROM books"
    books = @session.execute(query).to_a

    rated_books = books.map do |book|
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

    @top_books = rated_books.sort_by { |book| -book['avg_score'] }.first(10)
  end
  
  def search
    query = "SELECT * FROM books WHERE summary LIKE ?"
    @books = @session.execute(query, arguments: ["%#{params[:query]}%"]).to_a
    @books = @books.paginate(page: params[:page], per_page: 10)
  end

  def index
    @results = run_selecting_query(TABLE_NAME)
  end

  def show
    result = run_selecting_query(TABLE_NAME, "id = #{params[:id]}")
    result.each do |b|
      @book = b
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
      filled_params[key] = value if value.present?
    end

    filled_params.each do |key, value|
      run_update_query(TABLE_NAME, params[:id], key, value) if key != "id"
    end
  end

  def new
  end

  def create
    filled_params = {}
    params[:upd_form].each do |key, value|
      filled_params[key] = value if value.present?
    end
    run_inserting_query(TABLE_NAME, filled_params)
  end

  def destroy
    run_delete_query_by_id(TABLE_NAME, params[:id])
  end

  private

  def session_connection
    @session = Cassandra.cluster(hosts: CASSANDRA_CONFIG[:hosts], port: CASSANDRA_CONFIG[:port]).connect('my_keyspace')
  end
end
