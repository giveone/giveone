class SiteController < ApplicationController
  layout "public"
  before_filter :authenticate_user!, except: [:index, :volunteer]

  def index
    #TODO: Hugh - Scrub this controller - none of these
    @nonprofits = Nonprofit.is_public.featured_from(Time.zone.now.to_date + 1.day).limit(16)
    @subscriber = Subscriber.new
  end

  def login
    @nonprofits = Nonprofit.all
    @subscriber = Subscriber.new
  end

  def volunteer
    @categories   = Category.all
    @activations  = Activation.all
    @public_theme = "orange"
  end

  def account
    @current_user = current_user
  end

  def donate
  end

  def wall_calendar
  end

  def legal
  end

  def faq
  end

  def contact
  end

  def send_feedback
    params[:email] = params[:email].to_s
    params[:message] = params[:message].to_s

    if params[:email] !~ Devise.email_regexp
      flash[:alert] = "Please enter a valid email address."
      render :contact
    elsif params[:message].blank?
      flash[:alert] = "Please enter a message to send."
      render :contact
    else
      SendFeedbackJob.new(params[:email], params[:message]).save
      flash[:notice] = "Thanks! We'll look at your message in a bit."
      redirect_to root_url
    end
  end


  def share
    @full_url = params[:url]
    if @full_url
      @full_url += "&"
    else
      @full_url = [root_url, '?'].join('') if !@full_url
    end
    params.each do |k,v|
        @full_url += "#{k}=#{v}&" if ["redirect_uri", "href", "app_id", "display"].include?(k)
    end
    render :layout => false
  end
end
