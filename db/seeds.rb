# CLEAR DATABASE
# @TODO: remove this comment when going live
#throw "ERROR: You're trying to truncate the database in production!" if ENV['RAILS_ENV'] == 'production'

ActiveRecord::Base.establish_connection
ActiveRecord::Base.connection.tables.each do |table|
  unless table == "schema_migrations"
    ActiveRecord::Base.connection.execute("TRUNCATE #{table};")
  end
end

User.create!(name: "Administrator", :email => "admin@give-one.org", :password => "spree123", :is_admin => true)
User.create!(name: "User", :email => "spree@example.com", :password => "password", :is_admin => false)

categories = [
  { name: 'Education & arts' },
  { name: 'Environment' },
  { name: 'Homelessness & poverty' },
  { name: 'Equality' },
  { name: 'Health & relief' },
  { name: 'Violence & bullying' }
].map{ |params| Category.create!(params) }

4.times do |i|
  Activation.create!({
    url: 'https://google.com',
    name: 'Rooftop Garden Clean Up at Hester St.',
    sponsor: 'Barrier Free Living',
    description: 'We’re gonna clean up LES park. Make sure to wear clothes you don’t mind getting dirty.',
    blurb: '...',
    spots_available: 32,
    where: '123 Hester St.',
    happening_on: DateTime.now + 1.day,
    time_range: '11-4pm (5 Hours)',
    category: categories[i]
  })
end

non_profits = [
  {
    website_url: 'https://google.com',
    name: 'Boys and Girls Club of America',
    description: 'For over 150 years, the Boys and Girls Club of America has been enabling our nation’s youth to reach their full potential as productive, caring, responsible citizens. With the simple idea of getting kids off the streets, the Boys and Girls Club has changed the lives of so many young people, especially those who needed it the most, in so many communities across the U.S. Read more about their great programs at ',
    blurb: 'By subscribing to donate to today, you’re giving kids in your community hope and opportunity.'
  }, {
    website_url: 'https://google.com',
    name: 'Environmental Defense Fund',
    description: 'The Environmental Defense Fund is fighting the most critical environmental problems facing our planet. Clean air and water. Abundant fish and wildlife. A stable climate. Their work protects nature and helps people thrive. Learn more about all that they do at ',
    blurb: 'By subscribing to donate to today, you’re supporting a cleaner, safer planet.'
  }, {
    website_url: 'https://google.com',
    name: 'The American Civil Liberties Union',
    description: 'For almost 100 years, the ACLU has been working to defend and preserve the individual rights and liberties guaranteed by the Constitution and laws of the United States. Check out more of the impactful work they do at ',
    blurb: 'By subscribing to donate to today, you’re defending our fundamental rights.'
  }, {
    website_url: 'https://feedingamerica.org',
    name: 'Feeding America',
    description: 'Feeding America is fighting to feed the hungry all over the country. In the U.S. alone, billions of pounds of food are wasted each year, yet every day, there are millions of children and adults who do not get the meals they need to thrive. Check out all the communities they serve at ',
    blurb: 'By subscribing to donate to today, you’re helping the fight to end hunger.',
  }, {
    website_url: 'https://plannedparenthood.org',
    name: 'Planned Parenthood',
    description: 'Planned Parenthood is America’s most trusted provider of reproductive health care, offering all people high-quality, affordable medical care. With over 650 health centers across the U.S., Planned Parenthood has been the health care choice for 1 in 5 women. To learn more about all the services they provide to local communities visit ',
    blurb: "By subscribing to donate to today, you’re supporting women's health and safety and our fundamental reproductive rights."
  }, {
    website_url: 'https://thetrevorproject.org',
    name: 'The Trevor Project',
    description: 'Every day, the Trevor Project saves lives by providing crisis intervention and suicide prevention services to lesbian, gay, bisexual, transgender and questioning (LGBTQ) young people, ages 13-24. There are so many challenges we face growing up, and while most of us are lucky to have the support of friends and family, there are many young people out there who don’t. Check out more of the amazing work they’re doing at ',
    blurb: 'By subscribing to donate to today, you’re ensuring a safe space for those who need it most.'
  }
].each_with_index.map do |params, index|
  Nonprofit.create!(params.merge({
    is_public: true,
    ein: "5#{index}-5555555",
    category: categories[index],
    featured_on: index.day.from_now.to_date #TODO: I dont think we need this attr
  }))
end
