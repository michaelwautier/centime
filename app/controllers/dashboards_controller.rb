class DashboardsController < ApplicationController
  def show
    @month = parsed_month
    @summary = Reports::MonthlySummary.new(current_user, month: @month)
    @recent_transactions = current_user.transactions.includes(:category).recent_first.limit(5)
  end
end
