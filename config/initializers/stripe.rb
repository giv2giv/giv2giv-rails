
Stripe.api_key = App.stripe["api_key"]

StripeEvent.configure do |events|

  events.subscribe 'charge.succeeded' do |event|
    StripeCallbacks.new.charge_succeeded(event)
  end # end charge.succeeded
  events.subscribe 'transfer.created' do |event|
    Rails.logger.debug event
    StripeCallbacks.new.transfer_created(event)
  end # end charge.succeeded
  events.subscribe 'transfer.paid' do |event|
    Rails.logger.debug event
    StripeCallbacks.new.transfer_paid(event)
  end # end charge.succeeded
  events.subscribe 'charge.failed' do |event|
    Rails.logger.debug event
    StripeCallbacks.new.charge_failed(event)
  end # end card.denied
	events.all do |event|  
  	log_entry = StripeLog.create_or_update(event)
    # Handle all event types - logging, etc.
    #event.type        #=> "charge.failed"
    #event.data.object #=> #<Stripe::Charge:0x3fcb34c115f8>
  end

end


