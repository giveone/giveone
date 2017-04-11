# Load order issue -- gotta load these here instead of development.rb
if Rails.env.development?
  Rails.application.config.action_controller.asset_host = Rails.application.secrets.host
  Rails.application.config.action_mailer.asset_host = "http://#{Rails.application.secrets.host}"
end
