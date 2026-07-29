class CategorizationRulesController < ApplicationController
  def index
    @rules = current_user.categorization_rules.includes(:category).ordered
    @rule = current_user.categorization_rules.new
  end

  def create
    @rule = current_user.categorization_rules.new(rule_params)

    if @rule.save
      redirect_to categorization_rules_path, notice: "Rule added."
    else
      @rules = current_user.categorization_rules.includes(:category).ordered
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    current_user.categorization_rules.find(params[:id]).destroy!
    redirect_to categorization_rules_path, notice: "Rule removed.", status: :see_other
  end

  private

  def rule_params
    params.require(:categorization_rule).permit(:pattern, :matcher_type, :category_id, :position)
  end
end
