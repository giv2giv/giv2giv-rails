
# Set up a dev environment that will work
if Rails.env.development?

	Charity.create(name: "Test charity 1", ein: "Test EIN 1", city: "Anycity")
	Charity.create(name: "Test charity 2", ein: "Test EIN 2", city: "Anycity")
	Charity.create(name: "Test charity 3", ein: "Test EIN 3", city: "Anycity")
	Charity.create(name: "Test charity 4", ein: "Test EIN 4", city: "Anycity")
	Charity.create(name: "Test charity 5", ein: "Test EIN 5", city: "Anycity")

	Share.create( stripe_balance: 0,
								etrade_balance: 0,
								dwolla_balance: 0,
								transit_balance: 0,
								share_total_beginning: 0,
								shares_added_by_donation: 0,
								shares_subtracted_by_grants: 0,
    						share_total_end: 0, 
    						donation_price: 123456.78,
    						created_at: DateTime.now,
    						updated_at: DateTime.now,
    						grant_price: 123456.78)

end