require 'will_paginate'
require 'will_paginate/array'

class Api::CharityController < Api::BaseController

  skip_before_filter :require_authentication, :only => [:index, :show]

  def index
    page = params[:page] || 1
    perpage = params[:per_page] || 10
    query = params[:query] || ""

    charities = []

    tags = Tag.find(:all, conditions: [ "name LIKE ?", "%#{query}%" ])

    tags.each do |tag|
      charities += tag.charities
    end

    charities += Charity.find(:all, :conditions=> [ "name LIKE ?", "%#{query}%" ])

    charities << Charity.find_by_ein(query)
    results = charities.compact.uniq.paginate(:page => page, :per_page => perpage)

    respond_to do |format|
      if !results.empty?
        format.json { render json: results }
      else
        format.json { render json: {:message => "Not found"}.to_json }
      end
    end
  end

  def show
    charity = Charity.find(params[:id])
    charity.activity_code = activity_tag_names(charity.activity_code)
    respond_to do |format|
      if charity
        format.json { render json: charity }
      else
        format.json { head :not_found }
      end
    end
  end

  def activities
    CharityImport::Classification::ACTIVITY
  end

  def activity_tag_name(code)
    activities[code]
  end

  def activity_tag_names(code)
    return nil if code.blank? || code == '0.0'

    code = code.to_i.to_s
    while code.length < 9 do
      code = code.prepend('0')
    end

    [activity_tag_name(code[0..2]),
     activity_tag_name(code[3..5]),
     activity_tag_name(code[6..8])]
  end

end
