module NewslettersHelper

  def login_and_goto(nextpath, *args)
    email_login_subscriber_url("%recipient.guid%", "%recipient.auth_token%", next: Rails.application.routes.url_helpers.send(nextpath, "%recipient.guid%", *args))
  end

  def newsletter_tweet_url(nonprofit, type, double_escape=true)
    # Get the string with variables
    case type.to_sym
    when :donor
      text = t("newsletter.share.twitter.text.donor", nonprofit: nonprofit.twitter_or_name, donors: nonprofit.donations.executed.count)
    when :subscriber
      text = t("newsletter.share.twitter.text.subscriber", nonprofit: nonprofit.twitter_or_name, nonprofit_url: nonprofit_url(nonprofit))
    else
      raise
    end
    tweet_url(text: text, related: nonprofit.twitter)
  end

  def newsletter_facebook_url(nonprofit, double_escape=false)
    fb_params = {
      display:      'popup',
      app_id:       FACEBOOK[:app_id],
      redirect_uri: root_url,
      link:         nonprofit_url(nonprofit),
      name:         nonprofit.name,
      description:  t("newsletter.share.facebook.text", donors: nonprofit.donations.executed.count, nonprofit: nonprofit.name),
      catption:     root_url,
      actions:      "[{'link':'#{nonprofit_url(nonprofit)}','name':'#{CONFIG[:name]}'}]"
    }
    share_url(url: "https://www.facebook.com/dialog/feed?#{fb_params.to_query}")
  end

end
