require "http"
require "json"
require "lnurl_pay"
# frozen_string_literal: true

class LightningTools
  class LightningAddress < LnurlPay
    class KeysendError < StandardError
    end

    # NOTE: regex taken from: https://emailregex.com
    LN_ADDRESS_REGEX = /\A(?<username>([\w+\-].?)+)@(?<domain>[a-z_\d\-]+(\.[a-z]+)*\.[a-z]+)\z/i.freeze
    TAG_KEYSEND = "keysend"

    attr_accessor :address, :domain, :username

    def self.valid?(value)
      return LN_ADDRESS_REGEX.match?(value.to_s)
    end

    def initialize(ln_address)
      self.address = ln_address.downcase
      result = LN_ADDRESS_REGEX.match(address)
      if result
        self.username = result["username"]
        self.domain = result["domain"]
      end
    end

    def to_s
      address
    end

    def fetch!
      @lnurlp_data = fetch_lnurlp_data!
      @keysend_data = fetch_keysend_data!
    end

    def fetch
      @lnurlp_data = fetch_lnurlp_data
      @keysend_data = fetch_keysend_data
    end

    def keysend_data
      @keysend_data ||= fetch_keysend_data!
    end

    def fetch_keysend_data
      begin
        fetch_keysend_data!
      rescue StandardError
        nil
      end
    end

    def fetch_keysend_data!
      begin
        keysend_response = HTTP.timeout(3).follow(max_hops: 4).get(keysend_url)
      rescue HTTP::Error => e
        raise KeysendError, "Failed to load LNURL #{e.message}"
      end
      raise KeysendError, "Failed to fetch keysend information" if !keysend_response.status.success?

      data = JSON.parse(keysend_response.body.to_s)

      raise KeysendError, "Invalid Keysend parameters" if (data["tag"] != TAG_KEYSEND || data["status"] != "OK")

      custom_data = data["customData"][0]

      raise KeysendError, "Pubkey does not exist" unless data.key?("pubkey")

      destination = data["pubkey"]
      custom_key = custom_data["customKey"]
      custom_value = custom_data["customValue"]

      { destination: destination, custom_key: custom_key, custom_value: custom_value }
    end

    def keysend_url
      "https://#{domain}/.well-known/keysend/#{username}"
    end

    def lnurlp_url
      "https://#{domain}/.well-known/lnurlp/#{username}"
    end
  end
end
