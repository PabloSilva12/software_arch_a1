class AuthorsController < ApplicationController

  TABLE_NAME = 'authors'

  def author_summary
    query = "SELECT id, name FROM authors"
    authors = @session.execute(query).to_a

    @authors = authors.map do |author|
      books_count = @session.execute("SELECT COUNT(*) FROM books WHERE author_id = ?", arguments: [author['id']]).first['count']
      average_score = @session.execute("SELECT AVG(score) FROM reviews WHERE book_id IN (SELECT id FROM books WHERE author_id = ?)", arguments: [author['id']]).first['system.avg(score)']
      total_sales = @session.execute("SELECT SUM(sales) FROM sales WHERE book_id IN (SELECT id FROM books WHERE author_id = ?)", arguments: [author['id']]).first['system.sum(sales)']

      author.merge('books_count' => books_count, 'average_score' => average_score, 'total_sales' => total_sales)
    end
    @authors.sort_by! { |author| author[params[:sort_by]] } if params[:sort_by]
    @authors = authors.select { |author| author[params[:filter_by]].to_s.include?(params[:filter_value]) } if params[:filter_by]
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
  @session = Cassandra.cluster(hosts: CASSANDRA_CONFIG[:hosts], port: CASSANDRA_CONFIG[:port]).connect('my_keyspace')
end





