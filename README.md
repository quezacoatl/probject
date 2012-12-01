__Description__

A lightweight actor-based concurrent object framework with each object running in it's own process.

__How does it work?__

Each new object will fork and open up two UNIX sockets, one for requests and one for responses. Each method invocation on the actor is really asynchronous, but one can wait for the method to return by reading from the response channel.

__Example__

This example is not very practical, but it illusstrates how Probject can be used.

```ruby
require 'net/http'
require 'probject'

class GoogleRequester < Probject::Actor

  def do_request
    @response = Net::HTTP.get('www.google.com', '/')
  end

  def response_length
    @response.length
  end
end

probjects = []

1.upto 5 do |i|
  probjects[i] = GoogleRequester.new

  probjects[i].async.do_request
end

1.upto 5 do |i|
  puts probjects[i].response_length
end
```

__Install__

    $ gem install probject

__Platform support__

This gem is written for MRI, where forking is the best way of implementing concurrenent applications, and real threading is not supported. If you use Rubinius or JRuby I would propose looking in to Celluloid.

_supported_

  * MRI (1.9+)

__License__

Released under the MIT License. See `LICENSE.txt`