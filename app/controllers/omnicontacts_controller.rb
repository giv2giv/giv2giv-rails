class OmnicontactsController < ApplicationController

	def callback
		@contacts = request.env['omnicontacts.contacts']
	  @user = request.env['omnicontacts.user']
	  Rails.logger.debug "List of contacts of #{@user[:name]} obtained from #{params[:importer]}:"
	  @contacts.each do |contact|
	    Rails.logger.debug "Contact found: name => #{contact[:name]}, email => #{contact[:email]}"
	  end
	end

	def fail
		redirect_to "https://giv2giv.org"
	end
end