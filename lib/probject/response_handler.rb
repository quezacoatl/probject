module Probject
  class ResponseHandler

    def initialize(channel)
      @channel = channel
      @responses = {}
      @blocks = {}
    end

    def get(id)
      unless has_result? id
        until get_result id
        end
      end
      @responses.delete id
    end

    def done?(id)
      has_result?(id) || get_results(id)
    end

    def register_block(id, block)
      @blocks[id] = block
    end

    private

    def has_result?(id)
      @responses.include? id
    end

    def get_results(id)
      while @channel.readable?
        return true if get_result(id)
      end
      false
    end

    def get_result(id)
      msg = @channel.get
      if msg[:type] == :return # return
        @responses[msg[:id]] = msg[:value]
        @blocks.delete msg[:id] # no more yielding after return
        return msg[:id] == id
      else # yield
        @blocks[msg[:id]].call msg[:value]
        false
      end
    end
  end
end