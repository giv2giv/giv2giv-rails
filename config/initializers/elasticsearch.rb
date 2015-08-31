require "faraday"
require "typhoeus/adapters/faraday"
Searchkick.client = Elasticsearch::Client.new(hosts: ["127.0.0.1:9200", "127.0.0.1:9201"], retry_on_failure: true)