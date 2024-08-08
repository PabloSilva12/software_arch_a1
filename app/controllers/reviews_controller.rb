class ReviewsController < ApplicationController

  TABLE_NAME = 'reviews'

  def index
    @results = run_selecting_query(TABLE_NAME)
  end

  def show
    @review = run_selecting_query(TABLE_NAME, "id = #{params[:id]}")
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
