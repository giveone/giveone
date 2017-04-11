class NewsletterMailer < BaseMailer
  helper :nonprofits
  helper :newsletters

  layout "newsletter"

  def daily_donor(newsletter_id, to=nil, is_first=false)
    @newsletter = Newsletter.find(newsletter_id)
    @nonprofit  = @newsletter.nonprofit

    key = is_first ? "first" : "subsequent"
    subject = t("newsletter.subject.#{key}", nonprofit: @newsletter.nonprofit.name)

    mail(to: Array.wrap(to), subject: subject) do |format|
      format.html
      format.text
    end
  end

  def daily_subscriber(newsletter_id, to=nil, is_first=false)
    @newsletter = Newsletter.find(newsletter_id)
    @nonprofit  = @newsletter.nonprofit

    key = is_first ? "first" : "subsequent"
    subject = t("newsletter.subject.#{key}", nonprofit: @newsletter.nonprofit.name)

    mail(to: Array.wrap(to), subject: subject) do |format|
      format.html
      format.text
    end
  end

  def self.batched_newsletter_for(newsletter_id, type, is_first=false)
    case type.to_sym
    when :donor
      daily_donor(newsletter_id, "%recipient%", is_first)
    when :subscriber
      daily_subscriber(newsletter_id, "%recipient%", is_first)
    else
      throw
    end
  end

  def self.batched_daily(type, newsletter_id, recipients={}, is_first=false)
    Rails.logger.info "Sending a daily newsletter batch to #{recipients.size} recipients..."

    @newsletter   = Newsletter.find(newsletter_id)
    mailer = NewsletterMailer.batched_newsletter_for(@newsletter.id, type, is_first)

    unless Rails.env.production?
      Rails.logger.info "Filtering recipients hash"
      recipients = MailRecipientsFilter.filter_recipients_hash(recipients)
    end

    Rails.logger.info "Running interceptors on daily newsletter batch"
    mailer.inform_interceptors

    if recipients.size.zero?
      # This is mostly for Staging
      Rails.logger.info "No recipients left to send! #{type}, #{newsletter_id}, #{is_first}"
      return
    end

    response = RestClient.post "https://api:#{Rails.application.secrets.mandrill_api_key}@api.mandrill.com/messages",
      'from'                => "#{Rails.application.secrets.name} <hello@#{Rails.application.secrets.host}>",
      'to'                  => recipients.keys,
      'recipient-variables' => recipients.to_json,
      'subject'             => mailer.subject,
      'text'                => mailer.text_part.decoded,
      'html'                => mailer.html_part.decoded,
      'o:campaign'          => "daily_#{type}_newsletter",
      'o:tag'               => "daily_#{type}_newsletter_#{@newsletter.nonprofit.featured_on}"

    Rails.logger.info "Response from Mandrill: #{response}"
  rescue => e
    puts "\nERROR: #{e}\n"
    puts e.respond_to?(:response) ? "\n#{e.response.inspect}\n" : "\n#{e.inspect}\n"
    raise e
  end

end
