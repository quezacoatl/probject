__Description__

A lightweight actor-based concurrent object framework with each object running in it's own process.

__How does it work?__

When a new object is created, it will fork and open up two UNIX sockets, one for requests and one for responses. Each method invocation on the actor is asynchronous, but one can optionally wait for the method to return by reading from the response channel, using a future.

To do asyncrhonous invocations, use `.async` or `.tell`
```ruby
probject.async.my_method # => nil
```

To do asyncrhonous invocations that return a future, use `.future` or `.ask`
```ruby
probject.future.my_method # => Probject::Future
```

To do syncrhonous invocations, just call the method as you normally would
```ruby
probject.my_method # => whatever my_method returns
```

__Example__

This example is not very practical, but it illustrates how Probject can be used.

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
  # do a synchronous request - will block until all previous requests have been handled
  puts probjects[i].response_length
  # could also be written as probjects[i].future.response_length.get
end
```

__Install__

    $ gem install probject

__Platform support__

This gem is written for MRI, where forking is the best way of implementing concurrenent applications, and real threading is not supported. If you use Rubinius or JRuby I would propose looking in to Celluloid.

Windows does not work for two reasons - no UNIX sockets and no forking implemented in Ruby.

_supported_

  * MRI (1.9+) on UNIX

__License__

Released under the MIT License. See `LICENSE.txt`.
