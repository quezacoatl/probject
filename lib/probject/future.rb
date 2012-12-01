module Probject
  class Future
    def initialize(response_handler, id)
      @response_handler = response_handler
      @id = id
    end

    def get
      @response_handler.get @id
    end

    def get!
      response = get
      raise response if response.kind_of? Exception
      response
    end

    def done?
      @response_handler.done? @id
    end
  end
end