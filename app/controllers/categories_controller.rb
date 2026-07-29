class CategoriesController < ApplicationController
  before_action :set_category, only: [ :edit, :update, :destroy ]

  def index
    @categories = current_user.categories.active.ordered
  end

  def new
    @category = current_user.categories.new(kind: params[:kind].presence_in(Category.kinds.keys) || "expense")
  end

  def create
    @category = current_user.categories.new(category_params)

    if @category.save
      redirect_to categories_path, notice: t(".created", default: "Category created.")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @category.update(category_params)
      redirect_to categories_path, notice: t(".updated", default: "Category updated.")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # Archive rather than destroy: transactions keep pointing at the category.
  def destroy
    @category.update!(archived_at: Time.current)
    redirect_to categories_path, notice: t(".archived", default: "Category archived."), status: :see_other
  end

  private

  def set_category
    @category = current_user.categories.active.find(params[:id])
  end

  def category_params
    params.require(:category).permit(:name, :kind, :color)
  end
end
