#!/bin/bash
cd /app && \
bundle exec rake assets:precompile && \
bundle exec rake db:migrate && \
bundle exec script/delayed_job restart && \
bundle exec unicorn -c /app/config/container/unicorn.rb
