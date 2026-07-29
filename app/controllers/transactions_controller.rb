class TransactionsController < ApplicationController
  before_action :set_transaction, only: [ :edit, :update, :destroy ]

  def index
    @month = parsed_month
    @transactions = current_user.transactions.includes(:category).in_month(@month).recent_first
    @transactions = @transactions.uncategorized if params[:filter] == "uncategorized"
  end

  def new
    @form = TransactionForm.new(user: current_user)
  end

  def create
    @form = TransactionForm.new(user: current_user, **transaction_form_params)

    if @form.save
      redirect_to transactions_path, notice: t(".created", default: "Transaction added.")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @form = TransactionForm.new(user: current_user, transaction: @transaction)
  end

  def update
    if params[:transaction]&.key?(:category_id) && !params[:transaction].key?(:amount)
      update_category_inline
    else
      update_via_form
    end
  end

  def destroy
    @transaction.destroy!
    redirect_to transactions_path, notice: t(".deleted", default: "Transaction deleted."), status: :see_other
  end

  private

  def set_transaction
    @transaction = current_user.transactions.find(params[:id])
  end

  def transaction_form_params
    params.require(:transaction)
      .permit(:amount, :direction, :booked_on, :description, :merchant_name, :category_id)
      .to_h.symbolize_keys
  end

  # Inline recategorization from the index row — the learning feedback loop hook.
  def update_category_inline
    category = current_user.categories.active.find_by(id: params[:transaction][:category_id])
    @transaction.update!(category: category, categorization_source: category ? "manual" : "none")

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace(@transaction, partial: "transactions/transaction", locals: { transaction: @transaction }) }
      format.html { redirect_back fallback_location: transactions_path, notice: t(".updated", default: "Transaction updated.") }
    end
  end

  def update_via_form
    @form = TransactionForm.new(user: current_user, transaction: @transaction, **transaction_form_params)

    if @form.save
      redirect_to transactions_path, notice: t(".updated", default: "Transaction updated.")
    else
      render :edit, status: :unprocessable_entity
    end
  end
end
