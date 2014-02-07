Stripe.api_key = App.stripe["api_key"]


StripeEvent.configure do |events|
  Rails.logger.debug "configure"
  events.subscribe 'charge.succeeded' do |event|
    StripeCallbacks.new.charge_succeeded(event)
  end # end charge.succeeded
end

StripeEvent.all do |event|
  	Rails.logger.debug "All"
  	log_entry = StripeLog.new(type: event.type, event: event)
  	log_entry.save!
    # Handle all event types - logging, etc.
    #event.type        #=> "charge.failed"
    #event.data.object #=> #<Stripe::Charge:0x3fcb34c115f8>
end


