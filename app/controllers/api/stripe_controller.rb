class Api::StripeController < Api::BaseController
  include StripeHelper
  before_filter :require_authentication

end