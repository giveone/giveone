#!/bin/bash
# .ebextensions/nginx/hooks/02_write_nginx_conf.sh
FILE="/etc/nginx/sites-available/elasticbeanstalk-nginx-docker-proxy.conf"

#----------------------------------------------------------------------
# write out htpasswd file and setup auth configs for nginx conf
#----------------------------------------------------------------------
AUTH_CONFIG="";
ENABLE_BASIC_AUTH=`/opt/elasticbeanstalk/lib/ruby/bin/get-config environment | jq '.["ENABLE_BASIC_AUTH"]'`;

if [ "$ENABLE_BASIC_AUTH" == "\"true\"" ]; then
  echo "giveone:\$apr1\$TmcMtS5h\$w2f9tLcBiA3Cu.b72jNXo." > /etc/nginx/.htpasswd;
  chown nginx:nginx /etc/nginx/.htpasswd;
  chmod 600 /etc/nginx/.htpasswd;

read -r -d '' AUTH_CONFIG <<-'EOC'
auth_basic "Restricted";
    auth_basic_user_file /etc/nginx/.htpasswd;
EOC

fi

#----------------------------------------------------------------------
# write out nginx config file
#----------------------------------------------------------------------
sudo /bin/cat <<EOF >$FILE
map \$http_upgrade \$connection_upgrade {
  default       "upgrade";
  ""            "";
}

server {
  listen 80;
  client_max_body_size 15M;
  gzip on;
  gzip_comp_level 4;
  gzip_types text/html text/plain text/css application/json application/x-javascript text/xml application/xml application/xml+rss text/javascript;

  if (\$time_iso8601 ~ "^(\d{4})-(\d{2})-(\d{2})T(\d{2})") {
    set \$year \$1;
    set \$month \$2;
    set \$day \$3;
    set \$hour \$4;
  }

  access_log /var/log/nginx/healthd/application.log.\$year-\$month-\$day-\$hour healthd;
  access_log /var/log/nginx/access.log;

  set \$is_production 1;

  # TODO: @DMITRI Remove the "production" OR condition at go-live
  if (\$http_host ~ (integration) ) {
    set \$is_production 0;
  }

  location / {
    set \$should_redirect_to_https 0;

    # Check if we need to redirect to https scheme
    if (\$http_x_forwarded_proto != 'https' ) {
      set \$should_redirect_to_https 1;
    }

    if (\$http_user_agent ~ sqsd) {
      set \$should_redirect_to_https 0;
    }

    if (\$should_redirect_to_https = 1) {
      rewrite ^ https://\$host\$request_uri? permanent;
    }

    proxy_pass            http://docker;
    proxy_http_version    1.1;
    send_timeout          3600;
    keepalive_timeout     3600;
    proxy_connect_timeout 3600;
    proxy_send_timeout    3600;
    proxy_read_timeout    3600;
    proxy_buffering       off;
    proxy_cache           off;
    #proxy_set_header     Connection '';
    proxy_set_header      Connection          \$connection_upgrade;
    proxy_set_header      Upgrade             \$http_upgrade;
    #proxy_set_header     Host \$http_host;
    proxy_set_header      Host                \$host;
    proxy_set_header      X-Real-IP           \$remote_addr;
    proxy_set_header      X-Forwarded-Proto   \$http_x_forwarded_proto;
    proxy_set_header      X-Forwarded-For     \$proxy_add_x_forwarded_for;
    $AUTH_CONFIG
  }

  location ~ ^/(health|apple-app-site-association|.well-known) {
    proxy_pass            http://docker;
    proxy_http_version    1.1;
    auth_basic            off;
  }

  location ~ ^/(t.*) {
    return 200;
  }

  location ~ ^/(favicon|assets|robots|sitemap|browserconfig|uploads|fonts/)  {
    root /app/public;
    allow all;
    gzip_http_version 1.0;
    gzip_static  on;
    expires      365d;
    add_header   Pragma "public";
    add_header   Last-Modified "";
    add_header   Cache-Control public;
    add_header   Access-Control-Allow-Origin *;
  }
}

EOF

sudo service nginx restart
