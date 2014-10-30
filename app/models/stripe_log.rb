class StripeLog < ActiveRecord::Base
 
  class << self

    def create_or_update(event = {})
      raise ArgumentError unless event.type.present?
      log = StripeLog.new
      log.type = event.type
      log.event = event
      log.save!
    end
  end # end self

end