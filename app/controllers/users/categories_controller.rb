class Users::CategoriesController < Users::BaseController
  before_action :set_category, only: %i[edit update destroy]

  def index
    @categories = current_user.categories.order(:name)
  end

  def new
    @category = current_user.categories.new
  end

  def create
    checker = Plans::UsageChecker.new(current_user)

    unless checker.can_create_category?
      redirect_to users_categories_path,
                  alert: "Seu plano gratuito permite até 4 categorias."
      return
    end

    @category = current_user.categories.new(category_params)

    if @category.save
      redirect_to users_categories_path,
                  notice: "Categoria criada com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @category.update(category_params)
      redirect_to users_categories_path,
                  notice: "Categoria atualizada com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @category.destroy
    redirect_to users_categories_path,
                notice: "Categoria removida com sucesso."
  end

  private

  def set_category
    @category = current_user.categories.find(params[:id])
  end

  def category_params
    params.require(:category).permit(:name, :icon, :color)
  end
end