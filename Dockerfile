FROM ruby:2.1.10

MAINTAINER giveone "dmitrivassilev@gmail.com"

COPY . /app

WORKDIR /app

RUN \
	curl -sL https://deb.nodesource.com/setup_6.x | bash - && \
	apt-get install -y \
  mysql-client nodejs libmagic-dev \
  graphicsmagick --fix-missing -y && \
  gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 && \
  echo "gem: --no-rdoc --no-ri" >> ~/.gemrc && \
  apt-get clean && \
	/bin/bash -l -c "bundle config --global silence_root_warning 1" && \
	/bin/bash -l -c "bundle install --jobs=4 --without development test" && \
	/bin/bash -l -c "npm install && npm install -g bower" && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN \
	echo '{ "allow_root": true }' > /app/.bowerrc && \
	/bin/bash -l -c "bundle install --jobs=4 --without development test" && \
  mkdir pids && \
  chmod +w pids && \
  chmod +x config/container/run.sh && \
  rm -rf /tmp/* /var/tmp/* /root/.npm /root/.node-gyp && \
  bundle clean

EXPOSE 9000

CMD ["config/container/run.sh"]
