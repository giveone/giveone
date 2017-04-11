Rails.application.config.paperclip_defaults = {
  path: "assets/photos/:style/missing.png",
  default_url: "assets/photos/:style/missing.png",
  storage: :s3,
  s3_protocol: Rails.env.development? ? :http : :https,
  s3_permissions: :public_read,
  s3_credentials: {
    :bucket => Rails.application.secrets.paperclip_bucket,
    :access_key_id => S3[:access_key_id],
    :secret_access_key => S3[:secret_access_key]
  },
  bucket: Rails.application.secrets.paperclip_bucket
}

# To use the CF hostname instead of S3
Rails.application.config.paperclip_defaults[:s3_host_alias] = Rails.application.config.action_controller.asset_host # CF?

# We don't need CF on development
Rails.application.config.paperclip_defaults[:url] = ":s3_alias_url" if !Rails.env.development?
