class UtilityMailer < BaseMailer
  default "to" => "support@#{Rails.application.secrets.host}"

  def site_feedback(from_email, message)
    @from_email = from_email
    @message = message

    mail(
      subject: "[#{Rails.application.secrets.name}] Site Feedback",
      reply_to: @from_email) do |format|
      format.text
    end
  end
end
