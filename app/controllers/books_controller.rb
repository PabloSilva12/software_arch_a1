class BooksController < ApplicationController
  TABLE_NAME = 'books'

  before_action :session_connection

  INDEX_NAME = 'books'

  def top_selling
    books_query = "SELECT id, name, author_id, number_of_sales, date_of_publication FROM books"
    books = @session.execute(books_query).to_a

    authors_query = "SELECT id, name FROM authors"
    authors = @session.execute(authors_query).to_a
    authors_map = authors.each_with_object({}) { |author, hash| hash[author['id']] = author['name'] }

    sales_query = "SELECT book_id, year, sales FROM sales"
    sales_data = @session.execute(sales_query).to_a

    sales_by_book_and_year = sales_data.group_by { |sale| sale['book_id'] }

    @top_selling_books = books.map do |book|
      author_name = authors_map[book['author_id']]
      total_sales = book['number_of_sales']

      publication_year = book['date_of_publication'].year
      sales_in_publication_year = sales_by_book_and_year[book['id']]&.select { |sale| sale['year'] == publication_year }&.sum { |sale| sale['sales'] } || 0

      total_author_sales = books.select { |b| b['author_id'] == book['author_id'] }.sum { |b| b['number_of_sales'] }

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
    query = "SELECT id, name FROM books"
    books = @session.execute(query).to_a

    rated_books = books.map do |book|
      book_id = book['id']

      avg_score = @session.execute("SELECT AVG(score) FROM reviews WHERE book_id = ? ALLOW FILTERING", arguments: [book_id]).first['system.avg(score)']

      reviews = @session.execute("SELECT * FROM reviews WHERE book_id = ? ALLOW FILTERING", arguments: [book_id]).to_a

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
    books_query = "SELECT * FROM books"
    all_books = @session.execute(books_query).to_a

    if params[:query].present?
      search_terms = params[:query].split(/\s+/)
      @books = all_books.select do |book|
        search_terms.any? { |term| book['summary'].downcase.include?(term.downcase) }
      end

      per_page = 10
      page = params[:page].to_i > 0 ? params[:page].to_i : 1
      total_books = @books.size
      @books = @books.slice((page - 1) * per_page, per_page) || []

      @total_pages = (total_books / per_page.to_f).ceil
      @current_page = page

      author_ids = @books.map { |book| book['author_id'] }.uniq

      authors = []
      author_ids.each do |author_id|
        author_query = "SELECT id, name FROM authors WHERE id = ?"
        author = @session.execute(author_query, arguments: [author_id]).first
        authors << author if author
      end

      @authors_map = authors.each_with_object({}) do |author, hash|
        hash[author['id']] = author['name']
      end
    else
      @books = []
      @total_pages = 0
      @current_page = 0
      @current_page = 0
    end
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
    book_id = Cassandra::Uuid.new(params[:book_id])
    result = run_selecting_query(TABLE_NAME, "id = #{book_id}")
    result.each do |s|
      @to_edit = s
    end
  end

  def update
    book_id = Cassandra::Uuid.new(params[:id])
    author_id = Cassandra::Uuid.new(params[:author_id])

    filled_params = {
      'name' => params[:name],
      'summary' => params[:summary],
      'date_of_publication' => params[:date_of_publication],
      'number_of_sales' => params[:number_of_sales].to_i,
      'author_id' => author_id
    }

    filled_params.each do |key, value|
      if value.present?
        run_update_query(TABLE_NAME, book_id, key, value)
      end
    end

    # Update Elasticsearch document
    ElasticsearchClient.index_document(INDEX_NAME, book_id, filled_params)

    redirect_to book_path(book_id)
  end

  def new
    authors_query = "SELECT id, name FROM authors"
    authors = @session.execute(authors_query).to_a

    @authors = authors.map do |author|
      {
        'id' => author['id'].to_s,
        'name' => author['name']
      }
    end
  end

  def create
    author_id = Cassandra::Uuid.new(params[:author_id])
    filled_params = {
      'id' => params[:id],
      'name' => params[:name],
      'summary' => params[:summary],
      'date_of_publication' => params[:date_of_publication],
      'number_of_sales' => params[:number_of_sales].to_i,
      'author_id' => author_id
    }

    run_inserting_query(TABLE_NAME, filled_params)

    # Index document in Elasticsearch
    ElasticsearchClient.index_document(INDEX_NAME, params[:id], filled_params)

    redirect_to books_path, notice: 'Book was successfully created.'
  end

  def destroy
    run_delete_query_by_id(TABLE_NAME, params[:id])

    # Delete document from Elasticsearch
    ElasticsearchClient.delete_document(INDEX_NAME, params[:id])

    redirect_to books_path, notice: 'Book was successfully deleted.'
  end

  private

  def session_connection
    @session = Cassandra.cluster(hosts: CASSANDRA_CONFIG[:hosts], port: CASSANDRA_CONFIG[:port]).connect('my_keyspace')
  end
end
