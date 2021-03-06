module Paypal
  module Express
    class Request < NVP::Request

      def setup(payment_requests, return_url, cancel_url, parameters={}, options = {})
        params = {
          :RETURNURL => return_url,
          :CANCELURL => cancel_url
        }.merge(parameters)
        if options[:no_shipping]
          params[:REQCONFIRMSHIPPING] = 0
          params[:NOSHIPPING] = 1
        end
        Array(payment_requests).each_with_index do |payment_request, index|
          params.merge! payment_request.to_params(index)
        end
        response = self.request :SetExpressCheckout, params
        Response.new response, options
      end

      def details(token)
        response = self.request :GetExpressCheckoutDetails, {:TOKEN => token}
        Response.new response
      end

      def transaction_details(transaction_id)
        response = self.request :GetTransactionDetails, {:TRANSACTIONID => transaction_id}
        Response.new response
      end

      def checkout!(token, payer_id, payment_requests)
        params = {
          :TOKEN => token,
          :PAYERID => payer_id
        }
        Array(payment_requests).each_with_index do |payment_request, index|
          params.merge! payment_request.to_params(index)
        end
        response = self.request :DoExpressCheckoutPayment, params
        Response.new response
      end

      def capture!(transaction_id, amount, currency_code=:USD, options={})
        params = {
          :AUTHORIZATIONID  => transaction_id,
          :AMT              => Util.formatted_amount(amount),
          :CURRENCYCODE     => currency_code,
          :COMPLETETYPE     => options.delete(:incomplete) ? 'NotComplete' : 'Complete'
        }.merge(options)
        response = self.request :DoCapture, params
        Response.new response
      end

      def void!(transaction_id, note=nil)
        params = {
          :AUTHORIZATIONID  => transaction_id,
          :NOTE             => note,
        }
        response = self.request :DoVoid, params
        Response.new response
      end

      def subscribe!(token, recurring_profile)
        params = {
          :TOKEN => token
        }
        params.merge! recurring_profile.to_params
        response = self.request :CreateRecurringPaymentsProfile, params
        Response.new response
      end

      def subscription(profile_id)
        params = {
          :PROFILEID => profile_id
        }
        response = self.request :GetRecurringPaymentsProfileDetails, params
        Response.new response
      end

      def renew!(profile_id, action, options = {})
        params = {
          :PROFILEID => profile_id,
          :ACTION => action
        }
        if options[:note]
          params[:NOTE] = options[:note]
        end
        response = self.request :ManageRecurringPaymentsProfileStatus, params
        Response.new response
      end

      def refund!(transaction_id, options = {})
        params = {
          :TRANSACTIONID => transaction_id,
          :REFUNDTYPE => :Full
        }
        if options[:invoice_id]
          params[:INVOICEID] = options[:invoice_id]
        end
        if options[:type]
          params[:REFUNDTYPE] = options[:type]
          params[:AMT] = options[:amount]
          params[:CURRENCYCODE] = options[:currency_code]
        end
        if options[:note]
          params[:NOTE] = options[:note]
        end
        response = self.request :RefundTransaction, params
        Response.new response
      end

    end
  end
end