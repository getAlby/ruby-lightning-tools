Money::Currency.register(
  {
    priority: 1,
    iso_code: "SATS",
    iso_numeric: "840",
    name: "Satoshi",
    symbol: "sats",
    subunit: "",
    subunit_to_unit: 1,
    decimal_mark: ".",
    thousands_separator: ","
  }
)
Money.add_rate("BTC", "SATS", 100_000_000.to_f)
Money.add_rate("SATS", "BTC", 1 / 100_000_000.to_f)

Money.locale_backend = :currency
Money.rounding_mode = BigDecimal::ROUND_HALF_UP
