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

**You must trigger the start of Neo4j in server and console for them to join the 'cluster'**

## Contributing

Want to help out on development? Feel free to fork us, make changes, and submit pull requests!

Grab an open issue or [contact us](#contact-us) to find out what we could use help with.


## Contact Us

[Chat Room](https://lightcastle.campfirenow.com/4d2e5)

[giv2giv website](http://www.giv2giv.org)

[email](mailto:info@giv2giv.org)
