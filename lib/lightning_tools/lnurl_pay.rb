# frozen_string_literal: true

require "http"
require "json"

module LightningTools
  class LnurlPay
    class LnurlPayError < StandardError
    end

    TAG_PAY_REQUEST = "payRequest"

    def self.build(recipient)
      if LightningTools::LnurlPay.valid?(recipient)
        LightningTools::LnurlPay.new(recipient)
      elsif LightningTools::LightningAddress.valid?(recipient)
        LightningTools::LightningAddress.new(recipient)
      else
        raise LnurlPayError, "Not a valid LNURL / Lightning Address"
      end
    end

    def self.valid?(value)
      return Lnurl.valid?(value)
    end

    def initialize(lnurlp_str)
      @lnurlp_str = lnurlp_str
    end

    def to_s
      @lnurlp_str
    end

    def fetch!
      @lnurlp_data = fetch_lnurlp_data!
    end

    def fetch
      @lnurlp_data = fetch_lnurlp_data
    end

    def fetch_lnurlp_data!
      begin
        lnurl_response = HTTP.timeout(3).follow(max_hops: 4).get(lnurlp_url)
      rescue HTTP::Error => e
        raise LnurlPayError, "Failed to load LNURL #{e.message}"
      end
      raise LnurlPayError, "Connection problem or invalid LNURL / Lightning Address" if !lnurl_response.status.success?

      data = JSON.parse(lnurl_response.body.to_s)

      raise LnurlPayError, "LNURL Service doesn't have pay request tag" if data["tag"] != TAG_PAY_REQUEST

      callback = data["callback"].to_s.strip
      raise LnurlPayError, "Invalid callback url" unless URI.regexp.match?(callback)

      domain = URI(callback).host

      min = data["minSendable"].to_f.ceil
      max = data["maxSendable"].to_f.floor

      raise LnurlPayError, "Invalid pay parameters" if !(min && max) || min > max

      metadata = JSON.parse(data["metadata"])
      metadata_hash = Digest::SHA256.hexdigest(data["metadata"].to_json.to_s)

      identifier = ""
      description = ""
      image = ""
      payer_data = ""

      if data["metadata"].is_a?(Array)
        data["metadata"].each do |item|
          if item.is_a?(Array) && item.length == 2
            k, v = item
            case k
            when "text/plain"
              description = v.to_s
            when "text/identifier"
              identifier = v.to_s
            when "image/png;base64", "image/jpeg;base64"
              image = "data:#{k},#{v}"
            end
          end
        end
      end

      payer_data = data["payerData"] if data.key?("payerData")

      {
        allows_nostr: data["allowsNostr"] || false,
        callback: callback,
        comment_allowed: data["commentAllowed"].to_i,
        description: description,
        domain: domain,
        fixed: min == max,
        identifier: identifier,
        image: image,
        max: max,
        metadata_hash: metadata_hash,
        metadata: metadata,
        min: min,
        payer_data: payer_data,
        raw_data: data
      }
    end

    def fetch_lnurlp_data
      begin
        fetch_lnurlp_data!
      rescue StandardError
        nil
      end
    end

    def lnurlp_str
      @lnurlp_str
    end

    def lnurlp_data
      @lnurlp_data ||= fetch_lnurlp_data!
    end

    def min_sendable
      lnurlp_data[:min].to_i
    end

    def max_sendable
      lnurlp_data[:max].to_i
    end

    def comment_allowed?
      lnurlp_data[:comment_allowed] > 0
    end

    def comment_allowed
      lnurlp_data[:comment_allowed].to_i
    end

    def supported_payer_data
      (lnurlp_data[:payer_data].try(:keys) || []).map(&:to_sym)
    end

    def metadata_description
      description = lnurlp_data[:metadata].find { |type, _| type == "text/plain" }
      description[1] if description.any?
    end

    def request_invoice(args)
      msat = args[:satoshi] * 1000

      raise LnurlPayError, "Invalid amount" unless valid_amount?(msat)
      if args[:comment] && comment_allowed.positive? && args[:comment].length > comment_allowed
        raise LnurlPayError, "The comment length must be #{comment_allowed} characters or fewer"
      end

      invoice_params = { amount: msat.to_s }
      invoice_params[:comment] = args[:comment] if args[:comment]
      invoice_params[:payerdata] = args[:payerdata].to_json if args[:payerdata]

      invoice = generate_invoice(invoice_params)
      # validate payment request
      if invoice.payment_request.amount_raw != args[:satoshi]
        raise LnurlPayError,
              "Payment request: invalid amount (#{invoice.payment_request.amount_raw} != #{args[:satoshi]}"
      end
      invoice
    end

    def generate_invoice(params)
      callback_url = URI(lnurlp_data[:callback])
      callback_url.query = URI.encode_www_form(params)
      invoice_response = HTTP.get(callback_url)
      raise LnurlPayError, "Failed to fetch invoice information" if !invoice_response.status.success?

      invoice_data = JSON.parse(invoice_response.body.to_s)

      raise LnurlPayError, "Error: #{invoice_data["reason"]}" if invoice_data["status"] == "ERROR"

      payment_request = invoice_data["pr"].to_s
      raise LnurlPayError, "Invalid pay service invoice" unless payment_request && !payment_request.empty?

      invoice_args = { pr: payment_request }
      invoice_args[:verify] = invoice_data["verify"].to_s if invoice_data["verify"]

      return LightningTools::Invoice.new(invoice_args)
    end

    def lnurlp_url
      @lnurlp_url ||= Lnurl.decode_raw(@lnurlp_str.to_s)
    end

    def valid_amount?(amount)
      amount > 0 && amount >= min_sendable && amount <= max_sendable
    end
  end
end
