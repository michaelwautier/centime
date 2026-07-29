class ReportsController < ApplicationController
  def show
    @month = parsed_month
    @summary = Reports::MonthlySummary.new(current_user, month: @month)
    @breakdown = Reports::CategoryBreakdown.new(current_user, month: @month)
  end
end
