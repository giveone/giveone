Rails.application.config.paperclip_defaults = {
  path: "images/#{Rails.env}/:attachment/:id/:style.:extension",
  default_url: "assets/photos/:style/missing.png",
  storage: :s3,
  s3_protocol: Rails.env.development? ? :http : :https,
  s3_permissions: :public_read,
  s3_credentials: {
    :bucket => Rails.application.secrets.paperclip_bucket,
    :access_key_id => Rails.application.secrets.paperclip_aws_access_key_id,
    :secret_access_key => Rails.application.secrets.paperclip_aws_secret_access_key
  },
  bucket: Rails.application.secrets.paperclip_bucket
}
