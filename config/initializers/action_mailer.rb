if ActionMailer::Base.delivery_method == :smtp
  ActionMailer::Base.perform_deliveries = true
  ActionMailer::Base.raise_delivery_errors = true
end

Rails.application.configure do
  config.action_mailer.smtp_settings = {
    :address   => "smtp.mandrillapp.com",
    :port      => 587,
    :enable_starttls_auto => true,
    :user_name => Rails.application.secrets.mandrill_username,
    :password  => Rails.application.secrets.mandrill_api_key,
    :authentication => 'login',
    :domain => 'give-one.org'
  }
end

ActionMailer::Base.default_url_options = {
  host: Rails.application.secrets.host,
  protocol: Rails.application.secrets.protocol
}
