module Reports
  # Per-category totals for one month, both kinds, with transaction counts.
  class CategoryBreakdown
    Row = Data.define(:category, :cents, :count)

    def initialize(user, month: Date.current)
      @user = user
      @month = month.beginning_of_month
    end

    def expenses = rows.select { |row| row.cents.negative? }.sort_by(&:cents)
    def incomes = rows.select { |row| row.cents.positive? }.sort_by { |row| -row.cents }

    private

    def rows
      @rows ||= begin
        categories = @user.categories.index_by(&:id)
        @user.transactions.in_month(@month)
          .group(:category_id)
          .pluck(:category_id, Arel.sql("SUM(amount_cents)"), Arel.sql("COUNT(*)"))
          .map { |category_id, cents, count| Row.new(category: categories[category_id], cents: cents, count: count) }
      end
    end
  end
end
