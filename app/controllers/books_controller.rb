class BooksController < ApplicationController

  TABLE_NAME = 'books'

  before_action :session_connection

  def top_selling
    # Query to fetch all books with their authors
    books_query = "SELECT id, name, author_id, number_of_sales, date_of_publication FROM books"
    books = @session.execute(books_query).to_a

    authors_query = "SELECT id, name FROM authors"
    authors = @session.execute(authors_query).to_a
    authors_map = authors.each_with_object({}) { |author, hash| hash[author['id']] = author['name'] }

    sales_query = "SELECT book_id, year, sales FROM sales"
    sales_data = @session.execute(sales_query).to_a

    # Agrupar las ventas por libro y por año
    sales_by_book_and_year = sales_data.group_by { |sale| sale['book_id'] }

    @top_selling_books = books.map do |book|
      author_name = authors_map[book['author_id']]
      total_sales = book['number_of_sales']

      # Verificar si el libro estuvo en el top 5 de ventas en su año de publicación
      publication_year = book['date_of_publication'].year
      sales_in_publication_year = sales_by_book_and_year[book['id']]&.select { |sale| sale['year'] == publication_year }&.sum { |sale| sale['sales'] } || 0

      # Calcular el total de ventas para el autor
      total_author_sales = books.select { |b| b['author_id'] == book['author_id'] }.sum { |b| b['number_of_sales'] }

      # Identificar si estuvo en el top 5
      top_5_in_year = sales_by_book_and_year.values.flatten.select { |sale| sale['year'] == publication_year }
                                           .sort_by { |sale| -sale['sales'] }.first(5).any? { |sale| sale['book_id'] == book['id'] }

      book.merge(
        'author_name' => author_name,
        'total_sales' => total_sales,
        'total_author_sales' => total_author_sales,
        'top_5_in_year' => top_5_in_year ? "Yes" : "No"
      )
    end

    @top_selling_books = @top_selling_books.sort_by { |book| -book['total_sales'] }.first(50)
  end

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
