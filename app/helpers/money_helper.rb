module MoneyHelper
  def format_cents(cents, currency = current_user&.currency || "EUR")
    number_to_currency(cents / 100.0, unit: currency_symbol(currency))
  end

  # Signed amount with color: income green, expense red.
  def amount_tag(transaction)
    css = transaction.income? ? "text-emerald-600" : "text-gray-900"
    sign = transaction.income? ? "+" : ""
    tag.span("#{sign}#{format_cents(transaction.amount_cents, transaction.currency)}", class: "font-medium tabular-nums #{css}")
  end

  private

  def currency_symbol(currency)
    { "EUR" => "€", "USD" => "$", "GBP" => "£" }.fetch(currency, "#{currency} ")
  end
end
