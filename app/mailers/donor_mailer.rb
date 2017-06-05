require 'mandrill'

class DonorMailer < BaseMailer

  def stripe_payment_receipt(donor)
    card = donor.cards.last

    return if card.nil?

    fullname = card.name
    category = card.nonprofit.category.name
    amount = "$#{"%.2f" % (card.amount * 30)}"
    month_year = (DateTime.now - 30).strftime('%B %Y')

    vars = [
      {
        name: 'fullname',
        content: fullname
      },
      {
        name: 'category',
        content: category
      },
      {
        name: 'amount',
        content: amount
      },
      {
        name: 'month_year',
        content: month_year
      }
    ]

    begin

    mandrill = Mandrill::API.new Rails.application.secrets.mandrill_api_key
    mandrill.messages.send_template(
      'payment-receipt',
      '',
      {
        'to' => [{
          'email' => card.email
        }],
        'subject' => "Thank you for your donation",
        'from_name' => Rails.application.secrets.name,
        # 'from_email' => "hello@#{Rails.application.secrets.host}",
        'from_email' => "hello@give-one.org",
        'global_merge_vars' => vars
      }
    )
    rescue Exception => e
      Rails.logger.info "Failed: mandrill.messages.send_template('payment-receipt', ...) #{e.to_s}"
    end
  end

  def thankyou(donor_id)
    @donor = Donor.find(donor_id)

    card = @donor.cards.last

    return if card.nil?

    category = card.nonprofit.category.name
    amount = "$#{"%.2f" % card.amount}"

    vars = [
      {
        name: 'category',
        content: category
      },
      {
        name: 'amount',
        content: amount
      }
    ]

    begin

    mandrill = Mandrill::API.new Rails.application.secrets.mandrill_api_key
    mandrill.messages.send_template(
      'thankyou',
      '',
      {
        'to' => [{
          'email' => @donor.subscriber.email
        }],
        'subject' => "Thank You",
        'from_name' => Rails.application.secrets.name,
        # 'from_email' => "hello@#{Rails.application.secrets.host}",
        'from_email' => "hello@give-one.org",
        'global_merge_vars' => vars
      }
    )
    rescue Exception => e
      Rails.logger.info "Failed: mandrill.messages.send_template('thankyou', ...) #{e.to_s}"
    end
  end

  def cancelled(donor_id)
    @donor = Donor.find(donor_id)
    last_donation = @donor.last_executed_donation

    @last_day = last_donation ? last_donation.executed_at.to_date + 30.days : Date.today

    mail(to: @donor.subscriber.email, subject: "Your #{Rails.application.secrets.name} donations have been cancelled") do |format|
      format.html { render layout: 'base' }
    end
  end

  def uncancelled(donor_id)
    @donor = Donor.find(donor_id)

    mail(to: @donor.subscriber.email, subject: "Welcome back to #{Rails.application.secrets.name}!") do |format|
      format.html { render layout: 'base' }
    end
  end

  def donation_failed(donor_id)
    @donor = Donor.find(donor_id)

    mail(to: @donor.subscriber.email, subject: "Oops! Your credit card didn’t process") do |format|
      format.html { render }
    end
  end

  def receipt(donation_id, stripe_charge)
    @donation = Donation.find(donation_id)
    @donor = @donation.donor
    @subscriber = @donor.subscriber
    @nonprofits = @donation.nonprofits
    @charge = stripe_charge

    mail(to: @subscriber.email, subject: "Your #{Rails.application.secrets.name} receipt [##{'%08d' % @donation.id}]")
  end

end
