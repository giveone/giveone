<img src="https://give-one.org/assets/public/Hero-Give-b6fc91be864ace0cdc9d041d9df473ca3172f6d1137c521fe0e3a284fb1c3c2b.png"  width=200 />
## What is Give One?
[Give One](https:/give-one.org/) is a platform that makes giving back to your community easy.


### The Problem

It’s no secret that charitable giving and volunteering is prone to rise in times of uncertainty; spurred by natural disasters, human tragedies, and divisive political turbulence. In inspiring displays of human resilience, we turn these negative events into positive outcomes, fueling the healing and growth of our society at large.

Unfortunately for the organizations that make these positive changes possible, however, this irregular pattern of “peaks and valleys” in donations and volunteer efforts are, by their nature, difficult or impossible to predict. Without regular, ongoing, predictable income, it’s difficult to plan ahead. We want to give the most noble organizations in our culture the space and the capital to “think big.”

### Our Solution

Give One is a platform for charitable giving that aims to make donations regular and manageable.

The platform allows users to donate small amounts of money or time to causes they care about in under 60 seconds. Users can set their accounts to donate between 10 cents and $1 per day to six possible causes: education and arts, the environment, homelessness and poverty, equality, health and relief, and violence and bullying.

### How We Operate

Give One is a non-profit federal tax-exempt organization under section 501(c)(3) of the Internal Revenue Code, EIN 81-4924613, so all donations are tax deductible. Funds donated are provided directly to selected charities, Give One doesn’t take a penny.

Run by a team of volunteers, administrative costs are supported by private philanthropy, ensuring that every dollar raised goes directly to supporting the causes that users care about most.

### How it Works

Give One is built on the open-sourced code of Kickstarter cofounder Perry Chen’s [Dollar A Day](http://dollaraday.co/), which allows recurring donations, processed through Stripe.

Credit card payments are processed through [Stripe](https://stripe.com/), which takes a 2.2% + $0.30 processing fee, or 3.5% for American Express. Donations are processed once a month (30 days from the date that users sign up) rather than daily to avoid surplus processing fees.

Changing billing information and supported causes is managed through user accounts and reflected on the next sequential billing cycle.

### Platform Goals
Our goal for the remainder of 2017 and 2018 is to get an initial user base of 2,740 users to an average donation total of $1 per day, which would facilitate $1 million in donations per year.

On a longer timeline, Give One aims to be a central donation platform for a broad variety of charitable organizations, facilitating recurring donations that are effortless for users, but transformatively impactful for organizations with a positive impact in our world.


#### Short-Term Goals
These are the key features we want to accomplish over the next few quarters.

- Multiple Donations Management

One of the key ambitions for the Give One platform is to provide users with the ability to manage multiple recurring donations. Currently, users must create separate accounts to manage individual donations. An early focus for the platform’s roadmap is to allow users to “subscribe” to multiple charities, displayed on their user profile. From that profile/account page, users can deactivate and reactivate donations via their user profile at will.

- Donation Index Page

When Give-One has reached a significant number of charities, users should be able to see smaller representations of charities and browse and filter by categorical focus to find the organizations that they’d like to donate toward.

- Custom Landing Pages

Charitable organizations should be able to create their own identities within the Give One platform, standing up unique landing pages that allow users to donate to their causes. This would involve direct integration with the Stripe Connect feature to handle disbursement to third parties.

Users will be able to add these charities to their donation accounts and manage their recurring donations via their account page.

#### Long-Term Goals
Broader, more abstract, reach goals.  These priorities/ideas are liable to change.

- 1% Donation Planning Tool

The central thesis at the heart of Give One is that making small donations, at scale, can make a big collective impact. If each of us gave only 1% (of our time or our income) to causes that we cared about, we could make a tremendous difference in our communities, our countries, and for our planet.

A key product feature on Give One’s roadmap is an interactive utility that allows users to calculate and visualize what recurrent donations of their 1% could look like, then allocate their 1% to causes that matter most to them individually.

 Ideally, users would be able to enter their yearly salary to calculate 1% of their total income, divided by month, week, and day (calculations are performed locally to avoid privacy concerns). The platform would display interface elements representing various charitable causes (categories) and the organizations (charities) available for each, allow users to select how much of “their 1%” would be allocated to each individual category or specific organization.

---

#### Technical Details

Give One is a Ruby 2.1.x Rails 4.1.13 app built on top of a lot of great services & open-source software:

  * [AWS Elastic Beanstalk](https://aws.amazon.com/elasticbeanstalk/) for deployment and configuration management.
  * [Circle CI](https://circleci.com/) for testing and continuous integration.
  * [unicorn](http://unicorn.bogomips.org/) is included in the Gemfile, but it should be fine with puma, etc.
  * [Stripe](https://stripe.com/) for payments (explained below).
  * [Mandrill](http://www.mandrill.com/) for sending transacation emails.
  * [Mailchimp](http://www.mailchimp.com/) for sending newsletter emails.
  * [delayed_job](https://github.com/collectiveidea/delayed_job) to run async jobs.


#### Getting Started

For development environments, just install ruby >=2 then setup your database:

`bundle exec rake db:recreate`

[Pow](http://pow.cx/) as development server and [rbenv](https://github.com/sstephenson/rbenv) as a Ruby version manager work great for running the webapp locally.

#### Payments

This app supports Stripe as a payment method:

  * Donors may donate a variable amount (predetermined from a set of small amounts) if they like a particular nonprofit, let a donor
    cancel a his or her donation if he or she doesn't wish to continue.
  * Overhead: you'll need to be a 501c3 to offer tax deductions to US donors, but their dashboard is very useful for that accounting if you are
  * Fees: 2.9% * donation amount + $0.30
  * Payouts: requires you to setup and handle disbursements.
  * Metadata: subscriptions are tagged with metadata for easier disbursement via the Stripe backend.

#### Emails

The platform is built to send emails via Mandrill (over SMTP and their API).

#### Deployment

The platform is built to run on the AWS Elastic Beanstalk service.  Deploying can be done via the GUI or using the EB CLI

#### Models

NB: the `User` model is currently reserved for admin use, for which it uses Devise.

#### Testing

```
RAILS_ENV=test bundle exec rake db:drop db:create db:migrate
bundle exec rspec test
```

#### License
The code is MIT-licensed, so about as unrestrictive as it gets!  We hope this could be a starting point for similar platforms, regardless of intended use, proprietary or otherwise.
