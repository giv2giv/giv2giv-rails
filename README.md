## Welcome to the giv2giv API
   
This API provides simple REST endpoints for features shared by the front end applications (also located in this github account). It uses JRuby, Rails and embedded Neo4j (currently v1.9.M03).

You can jump into our [chat room](https://lightcastle.campfirenow.com/4d2e5) to keep up with development as it happens.

Want to help out? Checkout [giv2giv](http://www.giv2giv.org) and see [Contributing](#contributing).

## Getting Started

1. Install Jruby

        # We are using rvm so this is how we installed jruby
        rvm install jruby-1.7.4

2. Clone giv2giv-rails

        git clone https://github.com/giv2giv/giv2giv-rails.git

3. Install gems

        bundle install

4. Start the server!

        rails s

5. Start your console!

        rails c

**You must trigger the start of Neo4j in server and console for them to cluster**

        # in console
        Donor.first
        # with server running
        curl -X POST -H "Content-Type: application/json" -d '{"email":"kmiller@ltc.com","password":"welcome"}' http://localhost:3000/api/sessions/create.json

### Importing Initial Charities

1. Stop the server if it's running

2. Start console and trigger neo4j start

        rails c
        Donor.first

3. In another terminal tab, download and import a single file

        bundle exec rake charity:import_xls xls_name=eo_xx.xls
        # Some output as charities are created

4. Confirm charities are available in console

        Charity.all.size # should be around 41

### Import ALL Charities

1. Stop the server if it's running

2. Start console and trigger neo4j start

        rails c
        Donor.first

3. In another terminal tab, download and import a single file

        bundle exec rake charity:import_all
        # takes > 40 minutes
        # Some output as charities are created

4. Confirm charities are available in console

        Charity.all.size # should be > 80,000

## What Next?

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

