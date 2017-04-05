class Admin::CategoriesController < Admin::BaseController
  before_filter :find_category, only: [:show, :edit, :update, :destroy]

  respond_to :html, :json

  def index
    @categories = Category.
      order("name ASC")
  end

  def show
    render :edit
  end

  def new
    @name = params[:name]
    @category = Category.new(name: @name)
  end

  def create
    @category = Category.new(category_params)
    @category.save
    respond_with(@category, location: admin_categories_url)
  end

  def edit
  end

  def update
    @category.update_attributes(category_params)
    respond_with(@category, location: edit_admin_category_url(@category))
  end

  def destroy
    @category.destroy
    respond_with(@category, location: admin_categories_url)
  end

  private
  def category_params
    params.require(:category).permit(:name, :slug, :description)
  end

  def find_category
    @category = Category.find_by_param(params[:id])
  end
end
