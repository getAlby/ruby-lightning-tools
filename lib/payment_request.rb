require "http"
require "json"
require "money"
require "bitcoin_rate"

class LightningTools
  class PaymentRequest
    class PaymentRequestError < StandardError
    end

    BOLT11_REGEX = /^lnbc[0-9a-z]+$/i.freeze

    attr_accessor :payment_request

    def self.valid?(value)
      return BOLT11_REGEX.match?(value.to_s)
    end

    def initialize(pr)
      self.payment_request = pr.downcase
    end
    
    def amount_in_fiat(currency = "usd")
      amount = invoice_data["amount"]
      LightningTools::BitcoinRate.new(currency).fiat_value_for(amount)
    end

    def amount
      Money.new(amount_raw, "SATS")
    end

    def amount_raw
      invoice_data["amount"]
    end

    def description
      invoice_data["description"]
    end

    def to_s
      payment_request.to_s
    end

    def payment_hash
      invoice_data["payment_hash"]
    end

    def invoice_data
      @decoded ||=
        begin
          decode_response = HTTP.get(decode_url)
          raise PaymentRequestError, "Failed to fetch bolt11 information" if !decode_response.status.success?
          JSON.parse(decode_response.body.to_s)
        end
    end

    def decode_url
      "https://api.getalby.com/decode/bolt11/#{payment_request}"
    end
  end
end
