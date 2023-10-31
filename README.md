<p align="center">
  <img width="100%" src="docs/Header.png">
</p>

# Lightning Tools for Ruby

A ruby gem that provides useful and common tools and helpers to build lightning web applications.

## 🚀 Quick Start

Add this line to your application's Gemfile:

```ruby
gem 'lnurl'
```

Or install it yourself as:

    $ gem install lnurl

## 🤙 Usage

### Lightning Address

The LightningAddress class provides helpers to work with lightning addresses

```ruby
ln_address = LightningTools::LightningAddress.new("hello@getalby.com")
ln_address.fetch!
puts ln_address.lnurlp_data
# => {:allows_nostr=>true,
#     :callback=>"https://getalby.com/lnurlp/hello/callback",
#     :comment_allowed=>255,
#     :description=>"",
#     :domain=>"getalby.com",
#     :max=>11000000000,
#     :metadata_hash=>"8664b8f91fdb09448e6ceed3a524c0ef6aaff17258ea2ff846ad6ede4716e769",
#     :metadata=>[["text/identifier", "hello@getalby.com"], ["text/plain", "Sats for Alby"]],
#     :min=>1000,
#     :payer_data=>{"name"=>{"mandatory"=>false}, "email"=>{"mandatory"=>false}, "pubkey"=>{"mandatory"=>false}},
#     ...
puts ln_address.keysend_data
# => {:destination=>"030a58b8653d32b99200a2334cfe913e51dc7d155aa0116c176657a4f1722677a3",
#     :custom_key=>"696969",
#     :custom_value=>"017rsl75kNnSke4mMHYE"}
```

#### Get an invoice

```ruby
ln_address = LightningTools::LightningAddress.new("hello@getalby.com")
ln_address.fetch!
invoice = ln_address.request_invoice(
  {
    satoshi: 21,
    comment: "Keep stacking", # optional
    payerdata: {              # optional
      name: "Satoshi",
      email: "satoshi@getalby.com"
    }
  }
)
puts invoice.payment_request # => lnbc210n1pj5pg9cpp5n0665qn5ec78vustz0wztqqqafych5xzkkp29a6kqxkga6xkml3qhp5lxz45yxgp3d6x7syxsupe7mzdz3m4c5m3w7fmdwf0x2jn6uafe9qcqzzsxqyz5vqsp5vjx6c2pzp0x0tagengwrvckwsrgtnyu6rrluh536n0lwdhhjdjks9qyyssq5p9lqnwg2fkjg02pura73uuhmgvnj6r0h326keywc9frd88gkz7xz3333qp2vqwdfp8e89vz7pa2uj66mcn2klrq3nuwf6k47twm7rgpd3kyj9
```

#### Verify a payment

If the lnurl provider supports LNURL-Verify you can get the link and make an HTTP request to verify payment

```ruby
ln_address = LightningTools::LightningAddress.new("hello@getalby.com")
ln_address.fetch!
invoice = ln_address.request_invoice({ satoshi: 21 })
puts invoice.verify # => https://getalby.com/lnurlp/hello/verify/smHi6XjfadAR7DNqcJDbLcgi
verify_response = HTTP.get(invoice.verify)
data = JSON.parse(verify_response.body.to_s)
puts data["settled"] # => true (OR false)
```

### LNURL Pay

The LnurlPay class provides helpers to work with lnurls

```ruby
lnurl = LightningTools::LnurlPay.new("lnurl1dp68gurn8ghj7em9w3skccne9e3k7mf0d3h82unvwqhksetvd3hs5c92yf")
puts lnurl.lnurlp_url
# => "https://getalby.com/lnurlp/hello"
lnurl.fetch!
puts lnurl.lnurlp_data
# => {:allows_nostr=>true,
#     :callback=>"https://getalby.com/lnurlp/hello/callback",
#     :comment_allowed=>255,
#     :description=>"",
#     :domain=>"getalby.com",
#     :max=>11000000000,
#     :metadata_hash=>"8664b8f91fdb09448e6ceed3a524c0ef6aaff17258ea2ff846ad6ede4716e769",
#     :metadata=>[["text/identifier", "hello@getalby.com"], ["text/plain", "Sats for Alby"]],
#     :min=>1000,
#     :payer_data=>{"name"=>{"mandatory"=>false}, "email"=>{"mandatory"=>false}, "pubkey"=>{"mandatory"=>false}},
#     ...
```

#### Get an invoice

Similar to Lightning Address

```ruby
lnurl = LightningTools::LnurlPay.new("lnurl1dp68gurn8ghj7em9w3skccne9e3k7mf0d3h82unvwqhksetvd3hs5c92yf")
lnurl.fetch!
invoice = lnurl.request_invoice(
  {
    satoshi: 21,
    comment: "Keep stacking", # optional
    payerdata: {              # optional
      name: "Satoshi",
      email: "satoshi@getalby.com"
    }
  }
)
puts invoice.payment_request # => lnbc210n1pj5pg9cpp5n0665qn5ec78vustz0wztqqqafych5xzkkp29a6kqxkga6xkml3qhp5lxz45yxgp3d6x7syxsupe7mzdz3m4c5m3w7fmdwf0x2jn6uafe9qcqzzsxqyz5vqsp5vjx6c2pzp0x0tagengwrvckwsrgtnyu6rrluh536n0lwdhhjdjks9qyyssq5p9lqnwg2fkjg02pura73uuhmgvnj6r0h326keywc9frd88gkz7xz3333qp2vqwdfp8e89vz7pa2uj66mcn2klrq3nuwf6k47twm7rgpd3kyj9
```

#### Verify amount

Useful to check amount before sending, can be used with Lightning Address instances as well

```ruby
lnurl = LightningTools::LnurlPay.new("lnurl1dp68gurn8ghj7em9w3skccne9e3k7mf0d3h82unvwqhksetvd3hs5c92yf")
lnurl.fetch!
puts lnurl.valid_amount?(0)
# => false
```

#### Build

Useful when dealing with send inputs where the recipient can be either an LNURL or Lightning Address

```ruby
lnurl = LightningTools::LnurlPay.build(recipient_param)
# => #<LightningTools::LightningAddress:0x00...> (if recipient is a lightning address)
# => #<LightningTools::LnurlPay:0x00...> (if recipient is an lnurl)
```

### LNURL

#### Encoding

```ruby
lnurl = LightningTools::Lnurl.new('https://lnurl.com/pay')
puts lnurl.to_bech32 # => LNURL1DP68GURN8GHJ7MRWW4EXCTNRDAKJ7URP0YVM59LW
```

#### Decoding

```ruby
LightningTools::Lnurl.valid?('nolnurl') #=> false

lnurl = LightningTools::Lnurl.decode('LNURL1DP68GURN8GHJ7MRWW4EXCTNRDAKJ7URP0YVM59LW')
lnurl.uri # => #<URI::HTTPS https://lnurl.com/pay>
```

By default we accept long LNURLs but you can configure a custom max length:
```ruby
lnurl = LightningTools::Lnurl.decode(a_short_lnurl, 90)
```

#### [Lightning Address](https://github.com/andrerfneves/lightning-address)

```ruby
lnurl = LightningTools::Lnurl.from_lightning_address('user@lnurl.com')
lnurl.uri # => #<URI::HTTPS https://lnurl.com/.well-known/lnurlp/user>
```

#### LNURL responses

```ruby
lnurl = LightningTools::Lnurl.decode('LNURL1DP68GURN8GHJ7MRWW4EXCTNRDAKJ7URP0YVM59LW')
response = lnurl.response # => #<Lnurl::LnurlResponse status="OK" ...
response.status # => OK / ERROR
response.callback # => https://...
response.tag # => payRequest
response.maxSendable # => 100000000
response.minSendable # => 1000
response.metadata # => [...]

invoice = response.request_invoice(amount: 100000) # (amount in msats) #<Lnurl::InvoiceResponse status="OK"
# or:
invoice = lnurl.request_invoice(amount: 100000) # (amount in msats)

invoice.status # => OK / ERROR
invoice.pr # => lntb20u1p0tdr7mpp...
invoice.successAction # => {...}
invoice.routes # => [...]

```

### Payment Request

```ruby
pr = LightningTools::PaymentRequest.new("lnbc210n1pj5pg9....rgpd3kyj9")
puts pr.amount
# => 21
puts pr.invoice_data
# {"currency"=>"bc",
#  "created_at"=>1698734264,
#  "expiry"=>86400,
#  "payee"=>"030a58b8653d32b99200a2334cfe913e51dc7d155aa0116c176657a4f1722677a3",
#  "msatoshi"=>21000,
#  "description_hash"=>"f9855a10c80c5ba37a0434381cfb6268a3bae29b8bbc9db5c9799529eb9d4e4a",
#  "payment_hash"=>"9bf5aa0274ce3c76720b13dc258000ea498bd0c2b582a2f75601ac8ee8d6dfe2",
#  "min_final_cltv_expiry"=>80,
#  "amount"=>21,
#  "payee_alias"=>"getalby.com"}
```

#### Valid

Only checks if the payment request is valid as per the bolt-11 regex

```ruby
LightningTools::PaymentRequest.valid?("lnbc210n1pj5pg9cpp5n0665qn5ec78vustz0wztqqqafych5xzkkp29a6kqxkga6xkml3qhp5lxz45yxgp3d6x7syxsupe7mzdz3m4c5m3w7fmdwf0x2jn6uafe9qcqzzsxqyz5vqsp5vjx6c2pzp0x0tagengwrvckwsrgtnyu6rrluh536n0lwdhhjdjks9qyyssq5p9lqnwg2fkjg02pura73uuhmgvnj6r0h326keywc9frd88gkz7xz3333qp2vqwdfp8e89vz7pa2uj66mcn2klrq3nuwf6k47twm7rgpd3kyj9")
# => true
```

### Invoice

Useful when you want to add additional information along with `payment_request` like `verify` and `preimage`

```ruby
invoice = LightningTools::Invoice.new({pr: "lnbc210n1pj5pg9cpp5n0665qn5ec78vustz0wztqqqafych5xzkkp29a6kqxkga6xkml3qhp5lxz45yxgp3d6x7syxsupe7mzdz3m4c5m3w7fmdwf0x2jn6uafe9qcqzzsxqyz5vqsp5vjx6c2pzp0x0tagengwrvckwsrgtnyu6rrluh536n0lwdhhjdjks9qyyssq5p9lqnwg2fkjg02pura73uuhmgvnj6r0h326keywc9frd88gkz7xz3333qp2vqwdfp8e89vz7pa2uj66mcn2klrq3nuwf6k47twm7rgpd3kyj9"})
# => true
invoice.payment_request
# => #<LightningTools::PaymentRequest:0x00...>
puts invoice.payment_request.amount
# => 21
```


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/bumi/lnurl-ruby.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).