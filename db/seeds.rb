# This seed file is good for resetting development environments.
throw "Sure you want to empty the database?" if Rails.env.production?

# CLEAR DATABASE
ActiveRecord::Base.establish_connection
ActiveRecord::Base.connection.tables.each do |table|
  unless table == "schema_migrations"
    ActiveRecord::Base.connection.execute("TRUNCATE #{table};")
  end
end

User.create!(name: "Administrator", :email => "admin@give-one.org", :password => "spree123", :is_admin => true)
User.create!(name: "User", :email => "spree@example.com", :password => "password", :is_admin => false)

Nonprofit.create!(ein: "55-5555555", blurb: "...", featured_on: Time.now, name: "Planned Parenthood", description: "Planned Parenthood Federation of America, Inc., or Planned Parenthood, is a nonprofit organization that provides reproductive health services both in the United States and globally.", is_public: true)
Nonprofit.create!(ein: "56-5555555", blurb: "...", featured_on: 2.day.from_now.to_date, name: "Environmental Defense Fund", description: "Environmental Defense Fund or EDF is a United States–based nonprofit environmental advocacy group. The group is known for its work on issues including global warming, ecosystem restoration, oceans, and human health, and advocates using sound science, economics and law to find environmental solutions that work", is_public: true)
Nonprofit.create!(ein: "57-5555555", blurb: "...", featured_on: 1.day.from_now.to_date, name: "National Alliance to End Homelessness", description: "The National Alliance to End Homelessness is a United States-based organization addressing the issue of homelessness. The Alliance provides data and research to policymakers and elected officials in order to inform policy debates.", is_public: true)
