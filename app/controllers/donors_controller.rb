require 'mandrill'

class DonorsController < ApplicationController
  protect_from_forgery :except => :payment_receipt

  before_filter :authenticate_user!, only: :index
  before_filter :admin_required, only: :index
  before_filter :require_donor, only: [:uncancel, :edit, :update]
  before_filter :initialize_donor, only: [:new, :create]

  respond_to :html, except: [:exists, :fetch_state_by_zip, :map]
  respond_to :json, only: [:exists, :fetch_state_by_zip, :map]

  def index
    @donors = Donor.active.order("created_at ASC")
    @subscriber = Subscriber.new
  end

  def new
    redirect_to account_path and return if current_user.present?
    @require_stripe_js = true
    @hide_footer = true
    @public_theme = "green"

    if params[:email].present?
      @subscriber = Subscriber.where(email: params[:email].to_s).first_or_initialize
      @donor.subscriber = @subscriber
      @donor.build_card(email: @subscriber.email)
    end

    @nonprofit = Nonprofit.find_by_param(params[:id])
    page_meta_tags
    respond_with(@donor, layout: "public")
  end

  def info
    @require_stripe_js = true
    @public_theme      = "green"
    @categories        = Category.all

    # @TODO: Unsure if this is needed
    if params[:email].present?
      @subscriber = Subscriber.where(email: params[:email].to_s).first_or_initialize
      @donor.subscriber = @subscriber
      @donor.build_card(email: @subscriber.email)
    end

    @nonprofits = Nonprofit.all

    respond_with(@donor, layout: "public")
  end

  def create
    @require_stripe_js = true
    @hide_header = true
    @hide_footer = true

    @donor.attributes        = donor_params
    @donor.card.ip_address   = request.ip
    @donor.card.stripe_token = params[:stripeToken] if params["stripeToken"].present?

    Donor.transaction do
      @new_user = User.create!({
        email: @donor.card.email,
        name: @donor.card.name,
        password: donor_params[:password],
      })

      # only sign in the user if the non-profit is on the index page
      if @donor.card.nonprofit.is_public
        sign_in @new_user
      end

      @donor.user = @new_user
      @donor.save!
      session[:thanks] = @donor.subscriber.name
      session[:nonprofit_id] = @donor.card.nonprofit.id
      session[:donor_name] = @donor.subscriber.name
      session[:donor_card_amount] = @donor.card.amount
      session[:nonprofit_category] = @donor.card.nonprofit.category.name
      redirect_to thanks_donors_url
    end
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
    flash[:notice] = e.message
    redirect_to new_donation_url(donor_card_params[:card_attributes][:nonprofit_id])
  end

  # "Change Billing Details"
  def edit
    @require_stripe_js = true
    @new_card = current_donor.cards.new
  end

  # Stripe webhook for when an invoice is successfully paid for
  def payment_receipt
    mandrill = Mandrill::API.new Rails.application.secrets.mandrill_api_key

    event_json = JSON.parse(request.body.read) # event data from Stripe

    if event_json["type"] != "invoice.payment_succeeded"
       render json: {}, status: 400
    else
      donor = Donor.find_by(stripe_customer_id: event_json["data"]["object"]["customer"])
      donor = Donor.find_by(stripe_customer_id: "cus_AT3dv800viOsas") unless donor # @TODO: remove once fully test -- used for integration environment tests temporarily
      DonorMailer.stripe_payment_receipt(donor).deliver_now if donor && event_json["data"]["object"]["amount_due"].to_i != 0
      render json: {}, status: 200
    end
  end

  # TODO cleanup
  def update
    @require_stripe_js = true
    @new_card            = DonorCard.new(donor_card_params[:card_attributes])
    @new_card.ip_address = request.ip
    @new_card.is_active  = false
    @new_card.donor      = current_donor # TODO inverse_of?
    @new_card.stripe_token = params[:stripeToken]
    @new_card.stripe_email = params[:stripeEmail]
    @new_card.save!

    was_failed = current_donor.failed?

    current_donor.reload
    current_donor.cards.active.where.not(id: @new_card.id).each(&:deactivate!)
    @new_card.activate!

    # If they're fixing their card, try the failed donation again.
    if donation = current_donor.donations.failed.first
      donation.fix!
    end

    if was_failed
      flash[:notice] = "Thanks! We'll try it again now, and let you know by email."
    else
      flash[:notice] = "Thanks! We'll use this card from here on out."
    end
    redirect_to root_url
  rescue ActiveRecord::RecordInvalid => e
    render :edit
  end

  def cancel
    # @TODO: DMITRI eventually have this not actually destroy the record (to allow uncancelling)
    # but also send the cancellation email
    @donor_card = DonorCard.find_by(email: current_user.email)
    redirect_to account_path and return if @donor_card.nil?
    @donor = @donor_card.donor
    customer = Stripe::Customer.retrieve(@donor.stripe_customer_id)
    customer.delete # deletes all subscriptions
    @donor.subscriber.destroy
    @donor.destroy
    @donor_card.destroy
    current_user.destroy
    flash[:notice] = "Sorry to see you go!"
    redirect_to root_url
  end

  def uncancel
    @creds = params[:donor_verification]

    # TODO test the @auth_method thing -- this is so users don't have to 2x auth
    #  when going to cancel via website (instead of email)
    if auth_method == :card || current_donor.card.valid_credentials?(@creds[:last_4], @creds[:exp_month], @creds[:exp_year])
      current_donor.uncancel!
      render json: {success: "Thanks, you've signed up to start donating again!"}
    else
      render json: {error: "Sorry, those were not the correct credentials!"}
    end
  end

  # TODO throttle this?
  def exists
    @donor = Subscriber.where(email: params[:email].to_s).first.try(:donor)

    if @donor
      if @donor.active?
        if @donor.cancelled?
          msg = "You've recently canceled. To start donating again, or otherwise manage your account,"
        else
          msg = "You're already a donor. To manage your account"
        end
      else
        msg = "You've recently canceled. To start donating again, or otherwise manage your account,"
      end

      json = { success: true, message: msg }
    else
      json = { success: false }
    end

    respond_to do |format|
      format.json do
        render json: json
      end
    end
  end

  # Verify the donor's info, and pass them on to status page (?)
  def verify
    if verify_donor
      json = { success: true, location: subscriber_url(current_subscriber) }
    else
      json = { success: false, message: "We couldn't verify this account. Please check your info." }
    end

    respond_to do |format|
      format.json do
        render json: json
      end
    end
  end

  def thanks
    @hide_header = true
    @hide_footer = true
    @public_theme = 'green'
    @name = session['thanks']
    @nonprofit = Nonprofit.find(session['nonprofit_id'])
    redirect_to(root_url) and return unless @name = session.delete(:thanks)
    render :thanks, layout: 'public'
  end

  def fetch_state_by_zip
    @json =
      if params[:zip] && params[:zip] =~ /\A\d\d\d\d\d\z/
        city, state = params[:zip].to_region.split(",")
        {city: city.strip, state: state.strip}
      else
        {}
      end
    respond_with(@json)
  end

  def map
    @donors = Donor.active
    @json = []
    @donors.each { |d| @json.push(:latitude => d.subscriber.latitude, :longitude => d.subscriber.longitude, :city => d.subscriber.city) }
    respond_with(@json)
  end

  protected
  def page_meta_tags
    @meta_tags['og:image']        = @nonprofit.photo.url
    @meta_tags['og:title']        = "Donate now: #{@nonprofit.name}"
    @meta_tags['twitter:image']   = "#{@nonprofit.photo.url.gsub(/https/, 'http')}"
    @meta_tags['twitter:title']   = "Donate now: #{@nonprofit.name}"
  end

  private
  def donor_params
    params.require(:donor).permit(
      :add_fee, :password, :public_name, {card_attributes: [:name, :email, :amount, :address_zip, :nonprofit_id ]}
    )
  end

  def donor_card_params
    params.require(:donor).permit(
      card_attributes: [:name, :email, :address_zip, :nonprofit_id ]
    )
  end
end
