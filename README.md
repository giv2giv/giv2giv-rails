## Welcome to the giv2giv API

This API provides simple REST endpoints for features shared by the front end applications (also located in this github account). It uses Ruby 1.9.3, Rails and MySQL.

You can jump into our [chat room](https://lightcastle.campfirenow.com/4d2e5) to keep up with development as it happens.

Want to help out? Checkout [giv2giv](http://www.giv2giv.org) and see [Contributing](#contributing).

## Getting Started

1. Install Ruby

        # We are using rvm (https://rvm.io/) so this is how we installed ruby
        rvm install ruby-1.9.3

2. Clone giv2giv-rails

        git clone https://github.com/giv2giv/giv2giv-rails.git

3. Install gems

        bundle install

4. Setup your database
(If this doesn't work, then you may need to install mysql, and change the
 information in config/database.yml.)

		rake db:setup
		

4. Start the server!

        rails s

5. Start your console!

        rails c

### Importing Initial Charities

1. Stop the server if it's running

2. Start console

        rails c

3. In another terminal tab, download and import a single file

        bundle exec rake charity:import_xls xls_name=eo_de.xls
        # Some output as charities are created

4. Confirm charities are available in console

        Charity.all.size # should be around 316

### Import ALL Charities

1. Stop the server if it's running

2. Start console

        rails c

3. In another terminal tab, download and import a single file

        bundle exec rake charity:import_all
        # takes > 40 minutes
        # Some output as charities are created

4. Confirm charities are available in console

        Charity.all.size # should be > 80,000

## What's' Next?

Check out the [Curl Examples](curl_examples.txt) for examples on how to use the API to build new clients.

## Coming Soon

We hope to get a reference client implementation (beyond the curl example above)

## Contributing

Want to help out on development? Feel free to fork us, make changes, and submit pull requests!

Grab an open issue or [contact us](#contact-us) to find out what we could use help with.


## Contact Us

[Chat Room](https://lightcastle.campfirenow.com/4d2e5)

[giv2giv website](http://www.giv2giv.org)

[email](mailto:info@giv2giv.org)
