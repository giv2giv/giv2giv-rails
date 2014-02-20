[![Stories in Ready](https://badge.waffle.io/giv2giv/giv2giv-rails.png?label=ready)](https://waffle.io/giv2giv/giv2giv-rails)

## Welcome to the giv2giv API

This API provides simple REST endpoints for features shared by the front end applications (also located in this github account). It uses Ruby 1.9.3, Rails and MySQL.

## Getting Started

1. Install pre-requisites
	apt-get install nodejs

2. Install Ruby
        # We use [rvm] (https://rvm.io/)
        rvm install ruby-1.9.3

3. Install gems
        bundle install

4. Set config/app.yml variables

5. Setup your database
(If this doesn't work, then you may need to install mysql, and/or change the information in config/database.yml.)

		rake db:setup
		
6. Start the server!

        rails s


You're off and running. Use your new API with a client like [https://github.com/giv2giv-jquery](https://github.com/giv2giv-jquery) or curl. See [Curl Examples](curl_examples.txt) for endpoint detail.


## Contributing

Want to help out on development? Feel free to fork us, make changes, and submit pull requests!

Grab an open issue or [contact us](#contact-us) to find out what we could use help with.


## Contact Us

[giv2giv website](http://www.giv2giv.org)

[email](mailto:hello@giv2giv.org)
