### Give One Micro-donation Platform Rails app

*(open-sourced by Give One, Inc. on TBD, 2017)*

#### Details

This is a Ruby 2.1.x Rails 4.1.13 app built on top of a lot of great services & open-source software:

  * [delayed_job](https://github.com/collectiveidea/delayed_job) to run async jobs.
  * [AWS Elastic Beanstalk](https://aws.amazon.com/elasticbeanstalk/) or [capistrano 3](http://capistranorb.com/) for deployment.  AWS EB can also be used for configuration management.
  * [unicorn](http://unicorn.bogomips.org/) is included in the Gemfile, but it should be fine with puma, etc.
  * [audited](https://github.com/collectiveidea/audited) is also included, and comes in handy quite often.
  * [Stripe](https://stripe.com/) for payments (explained below)
  * [MaxMind GeoIP](https://www.maxmind.com/en/geoip2-databases) for subscriber IP lookup.
  * [mandrill](http://www.mandrill.com/) for sending emails.

#### Getting Started

For development environments, just install ruby >=2 then setup your database:

`bundle exec rake db:drop db:create db:migrate db:seed`

[Pow](http://pow.cx/) as development server and [rbenv](https://github.com/sstephenson/rbenv) as a Ruby version manager work great for running the webapp locally.

#### Payments

This app supports Stripe as a payment method:

* Stripe
  * donors may donate a variable amount (predetermined from a set of small amounts) if they like a particular nonprofit, let a donor
    cancel a his or her donation if he or she doesn't wish to continue.
  * overhead: you'll need to be a 501c3 to offer tax deductions to US donors, but their dashboard is very useful for that accounting if you are
  * fees: 2.9% * donation amount + $0.30
  * payouts: requires you to setup and handle disbursements.
  * metadata: subscriptions are tagged with metadata for easier disbursement via the Stripe backend.

#### Emails

The app is built to send emails via Mandrill (over SMTP and their API).

#### Deployment

The app is built to run on the AWS Elastic Beanstalk service.  Deploying can be done via the GUI or using the EB CLI

* unicorn for app server
* nginx for web server / SSL termination
* any old MySQL database
* cron -- the app assumes you have cron running every 15 minutes, like so:
```
  # m  h dom mon dow command
  */15 * * * * export cd /apps/my_app_name/current; bin/rails runner -e $RAILS_ENV 'Cron.tab' > /tmp/cronout
```
* job server -- the app uses DelayedJob and provides rake/cap integration to restart it on deploys

#### Features

* Subscriber-only newsletters
* Donor-only newsletters
* Donations are batched and executed every 30 days to avoid paying fees for individual donations.
* Intercom.io integration

#### Models

NB: the `User` model is currently reserved for admin use, for which it uses Devise.

#### Testing

`RAILS_ENV=test bundle exec rake db:drop db:create db:migrate db:seed`
`bundle exec rspec test`

### Subscriber-only Scenario

```
SUBSCRIBER
  |
  -> EMAIL -> NEWSLETTER
  -> EMAIL -> NEWSLETTER
  -> EMAIL -> NEWSLETTER
  -> ...
```

### Donor Scenario

```
DONOR
  |
  -> SUBSCRIBER
    |
    -> EMAIL -> NEWSLETTER
    -> EMAIL -> NEWSLETTER
    -> EMAIL -> NEWSLETTER
    -> ...
  |
  -> CARD
    |
    -> DONATIONS
      |
      -> DONATION-NONPROFIT -> NONPROFIT
      -> DONATION-NONPROFIT -> NONPROFIT
      -> DONATION-NONPROFIT -> NONPROFIT
      -> ...
```

#### TODO

* Fill out missing functional tests
* Fill out missing unit tests
* Cleanup auth code in controllers
* A few models could benefit from a state machine: donation, donor, & subscriber.
* Update hashes to 1.9 hash syntax (ie replace hashrockets on symbol keys)
* Auto-create an Email record after we deliver emails, instead of manually doing it each time
* Other TODOs scattered around the app
