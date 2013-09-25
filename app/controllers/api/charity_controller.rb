require 'will_paginate'
require 'will_paginate/array'

class Api::CharityController < Api::BaseController

  skip_before_filter :require_authentication, :only => [:index,
                                                        :show]

  def index
    page = params[:page] || 1
    perpage = params[:per_page] || 10
    query = params[:query] || ""

    charities = []

    tags = Tag.find(:all, :conditions=> [ "name LIKE ?", "%#{query}%" ])
    tags.each do |tag|
      tag.charities.each do |c|
        charities << c
      end
    end

    Charity.find(:all, :conditions=> [ "name LIKE ?", "%#{query}%" ]).each do |c|
      charities << c
    end

    charities << Charity.find_by_ein(query)
    results = charities.compact.flatten.uniq.paginate(:page => page, :per_page => perpage)

    respond_to do |format|
      if !results.empty?
        format.json { render json: results }
      else
        format.json { render json: {:message => "Not found"}.to_json }
      end
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

end