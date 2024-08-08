class BooksController < ApplicationController

  TABLE_NAME = 'books'

  def top_rated
    query = "SELECT id, name FROM books"
    books = @session.execute(query).to_a

    rated_books = books.map do |book|
      avg_score = @session.execute("SELECT AVG(score) FROM reviews WHERE book_id = ?", arguments: [book['id']]).first['system.avg(score)']
      highest_review = @session.execute("SELECT * FROM reviews WHERE book_id = ? ORDER BY score DESC LIMIT 1", arguments: [book['id']]).first
      lowest_review = @session.execute("SELECT * FROM reviews WHERE book_id = ? ORDER BY score ASC LIMIT 1", arguments: [book['id']]).first

      book.merge('avg_score' => avg_score, 'highest_review' => highest_review, 'lowest_review' => lowest_review)
    end

    @top_books = rated_books.sort_by { |book| -book['avg_score'] }.first(10)
  end

  def top_selling
    query = "SELECT id, name, date_of_publication FROM books"
    books = @session.execute(query).to_a

    selling_books = books.map do |book|
      total_sales = @session.execute("SELECT SUM(sales) FROM sales WHERE book_id = ?", arguments: [book['id']]).first['system.sum(sales)']
      author_sales = @session.execute("SELECT SUM(sales) FROM sales WHERE book_id IN (SELECT id FROM books WHERE author_id = ?)", arguments: [book['author_id']]).first['system.sum(sales)']
      top_5_in_year = @session.execute("SELECT * FROM sales WHERE year = ? ORDER BY sales DESC LIMIT 5", arguments: [book['date_of_publication'].year]).any? { |s| s['book_id'] == book['id'] }

      book.merge('total_sales' => total_sales, 'author_sales' => author_sales, 'top_5_in_year' => top_5_in_year)
    end

    @top_selling_books = selling_books.sort_by { |book| -book['total_sales'] }.first(50)
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
    @book = run_selecting_query(TABLE_NAME, "id = #{params[:id]}")
  end

  def edit
    @to_edit = run_selecting_query(TABLE_NAME, "id = #{params[:id]}")
  end

  def update
    filled_params = {}
    params[:upd_form].each do |key, value|
      if value.present?
        filled_params[key] = value
      end
    end

    filled_params.each do |key, value|
      if key != "id" do
        run_update_query(TABLE_NAME, params[:id], key, value)
      end
    end

  end

  def new
  end

  def create
  end

  def delete
    run_delete_query_by_id(TABLE_NAME, params[:id])
  end
end
