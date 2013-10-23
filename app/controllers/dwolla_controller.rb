class DwollaController < Api::ApplicationController
  include DwollaHelper

  def receive_hook
    begin
      head :ok
    rescue Exception => e
      puts e.message  
      head :unauthorized
    end
  end
end