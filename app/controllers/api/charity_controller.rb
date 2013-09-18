require 'will_paginate'
require 'will_paginate/array'

class Api::CharityController < Api::BaseController

  before_filter :require_authentication, :only => [:show]

  def index
    page = params[:page] || 1
    per_page = [params[:per_page], 30].compact.min # limit to 30 results per page
    results = Charity.find(:all).paginate(:page => page)

    respond_to do |format|
      format.json { render json: results }
    end
  end

  def show
    charity = Charity.find(params[:id].to_s)

    respond_to do |format|
      if charity
        format.json { render json: charity }
      else
        format.json { head :not_found }
      end
    end
  end

  def search
    ss = params[:search_string]
    # FIXME sanitize_input !

    charities = []

    tags = Tag.all("name: \"#{ss}\"", :type => :fulltext)
    tags.each do |tag|
      tag.charities.each do |c|
        charities << c
      end
    end

    Charity.all("name: \"#{ss}\"", :type => :fulltext).each do |c|
      charities << c
    end
    charities << Charity.find_by_ein(ss)
    charities = charities.compact.flatten.uniq

    respond_to do |format|
      if !charities.empty?
        format.json { render json: charities }
      else
        format.json { head :not_found }
      end
    end
  end

end
