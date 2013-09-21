require 'will_paginate'
require 'will_paginate/array'

class Api::CharityController < Api::BaseController

  before_filter :require_authentication, :only => [:show]

  def index
    page = params[:page] || 1
    perpage = params[:per_page] || 1
    results = Charity.find(:all).paginate(:page => page, :per_page => perpage)

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
    ss = params[:keyword]

    charities = []

    tags = Tag.find(:all, :conditions=> [ "name LIKE ?", "%#{params[:keyword]}%" ])
    tags.each do |tag|
      tag.charities.each do |c|
        charities << c
      end
    end

    Charity.find(:all, :conditions=> [ "name LIKE ?", "%#{params[:keyword]}%" ]).each do |c|
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
