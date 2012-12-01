module Probject
  class Proxy

    def initialize(probject, invocation_type)
      @probject = probject
      @invocation_type = invocation_type
    end

    def method_missing(name, *args, &block)
      method = @probject.method("____#{name}_#{@invocation_type}")
      method.call(*args, &block)
    end
  end
end