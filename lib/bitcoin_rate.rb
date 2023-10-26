require "http"
require "json"
require "money"
require "redis"

class LightningTools
  class BitcoinRate
    attr_accessor :currency

    def initialize(currency)
      self.currency = currency.downcase
    end

    def cents_per_sat
      rate.cents.to_f / 100_000_000.to_f
    end

    def fiat_value_for(sats)
      Money.new((sats * cents_per_sat).ceil, currency)
    end

    def rate_float
      data_json[currency.upcase]["rate_float"]
    end

    def rate_string
      data_json[currency.upcase]["rate"]
    end

    def rate
      Money.from_amount(rate_float, currency)
    end

    def data_raw
      get_cached_rate || get_fresh_rate
    end

    def data_json
      JSON.parse(data_raw)
    end

    def get_fresh_rate
      get_fresh_rate_from_bitstamp || get_fresh_rate_from_coindesk
    end

    def get_fresh_rate_from_bitstamp
      # use bitstamp only for these currencies
      return unless currency.in?(%w[usd eur gbp])
      response = HTTP.get("https://www.bitstamp.net/api/v2/ticker/btc#{currency}")
      return nil if !response.status.success?
      bitstamp = JSON.parse(response.body.to_s)
      data = { updated_at: Time.now.to_i }

      m = Money.from_amount(bitstamp["last"].to_f, currency)
      rate_data = {
        code: currency.upcase,
        symbol: m.symbol,
        rate: m.format(delimiter: "", separator: ".", format: "%n"),
        rate_float: m.to_f,
        rate_cents: m.cents
      }
      data = rate_data.dup
      # nest it under the currency key for backwards compatibility
      data[currency.upcase] = rate_data.dup

      JSON
        .dump(data)
        .tap do |str|
          REDIS.set(redis_key, str)
          REDIS.expireat(redis_key, 10.minutes.from_now.to_i)
        end
    end

    def get_fresh_rate_from_coindesk
      response = HTTP.get("https://api.coindesk.com/v1/bpi/currentprice/#{currency}.json")
      return nil if !response.status.success?
      coindesk = JSON.parse(response.body.to_s)
      data = { updated_at: Time.now.to_i }

      m = Money.from_amount(coindesk["bpi"][currency.upcase]["rate_float"], currency)
      rate_data = {
        code: currency.upcase,
        symbol: m.symbol,
        rate: m.format(delimiter: "", separator: ".", format: "%n"),
        rate_float: m.to_f,
        rate_cents: m.cents
      }
      data = rate_data.dup
      # nest it under the currency key for backwards compatibility
      data[currency.upcase] = rate_data.dup

      JSON
        .dump(data)
        .tap do |str|
          REDIS.set(redis_key, str)
          REDIS.expireat(redis_key, 10.minutes.from_now.to_i)
        end
    end

    def get_cached_rate
      REDIS.get(redis_key)
    end

    def redis_key
      "rates:#{currency}"
    end
  end
end