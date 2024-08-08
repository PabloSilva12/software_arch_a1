class ReviewsController < ApplicationController

  TABLE_NAME = 'reviews'

  def index
    @results = run_selecting_query(TABLE_NAME)
  end

  def show
    @result = run_selecting_query(TABLE_NAME, params[:id])
  end

  def edit
  end

  def update
  end

  def new
  end

  def create
  end

  def delete
    run_delete_query_by_id(TABLE_NAME, params[:id])
  end
end
