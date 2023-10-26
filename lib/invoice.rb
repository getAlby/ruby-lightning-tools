require "payment_request"

class LightningTools
  class Invoice
    attr_accessor :payment_request, :preimage, :verify

    def initialize(args)
      self.payment_request = LightningTools::PaymentRequest.new(args[:pr])
      self.verify = args[:verify]
      self.preimage = args[:preimage]
    end
  end
end
