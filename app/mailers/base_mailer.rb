class BaseMailer < ActionMailer::Base
  helper ApplicationHelper

  prepend_view_path Rails.root.join('app/mailers/views')
  layout "base"

  FROM = "#{Rails.application.secrets.name} <hello@#{Rails.application.secrets.host}>"

  default from: FROM
end
