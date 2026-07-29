module Reports
  # Aggregates a user's transactions for the dashboard: month totals,
  # per-category expense breakdown, and an income/expense trend.
  class MonthlySummary
    Totals = Data.define(:income_cents, :expense_cents) do
      def net_cents = income_cents - expense_cents
    end

    def initialize(user, month: Date.current)
      @user = user
      @month = month.beginning_of_month
    end

    def totals
      @totals ||= begin
        income, expense = month_scope.pick(
          Arel.sql("COALESCE(SUM(amount_cents) FILTER (WHERE amount_cents > 0), 0)"),
          Arel.sql("COALESCE(-SUM(amount_cents) FILTER (WHERE amount_cents < 0), 0)")
        )
        Totals.new(income_cents: income || 0, expense_cents: expense || 0)
      end
    end

    # { "Groceries" => 12345, ... } expense cents per category name, largest first
    def expense_breakdown
      @expense_breakdown ||= month_scope.expenses
        .left_joins(:category)
        .group(Arel.sql("COALESCE(categories.name, 'Uncategorized')"))
        .sum(Arel.sql("-amount_cents"))
        .sort_by { |_name, cents| -cents }
        .to_h
    end

    # { Date => { income_cents:, expense_cents: } } for the trailing `months`
    def trend(months: 6)
      start = @month - (months - 1).months
      rows = @user.transactions
        .where(booked_on: start..@month.end_of_month)
        .group(Arel.sql("date_trunc('month', booked_on)::date"))
        .pluck(
          Arel.sql("date_trunc('month', booked_on)::date"),
          Arel.sql("COALESCE(SUM(amount_cents) FILTER (WHERE amount_cents > 0), 0)"),
          Arel.sql("COALESCE(-SUM(amount_cents) FILTER (WHERE amount_cents < 0), 0)")
        )
        .to_h { |month, income, expense| [ month, [ income, expense ] ] }

      (0...months).each_with_object({}) do |offset, series|
        month = start + offset.months
        income, expense = rows[month] || [ 0, 0 ]
        series[month] = { income_cents: income, expense_cents: expense }
      end
    end

    private

    def month_scope
      @user.transactions.in_month(@month)
    end
  end
end
