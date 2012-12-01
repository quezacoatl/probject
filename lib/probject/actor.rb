module Probject

  class TerminatedError < StandardError; end

  class UnsupportedError < StandardError; end

  class Actor

    def initialize
      @____request_channel = IChannel.new Marshal
      response_channel = IChannel.new Marshal
      @____response_handler = ResponseHandler.new response_channel
      @____pid = Actor.spawn self, @____request_channel, response_channel

      ObjectSpace.define_finalizer(self, self.class.finalize(@____pid))
    end

    def pid
      @____pid
    end

    def terminate(timeout = 10)
      raise_if_terminated!
      @____terminated = true
      if timeout && timeout != 0
        begin
          Timeout.timeout(timeout) do
            Actor.send_signal(@____pid, 'SIGTERM')
          end
        rescue Timeout::Error
          Actor.kill @____pid
        end
      else
        Actor.kill @____pid
      end
    end

    def terminated?
      @____terminated
    end

    # asynchronous call
    # returns nil
    def async
      raise_if_terminated!
      Proxy.new(self, :async)
    end
    alias_method :tell, :async

    # asynchronous call
    # returns Probject::Future
    def future
      raise_if_terminated!
      Proxy.new(self, :future)
    end
    alias_method :ask, :future

    def self.finalize(pid)
      proc { self.kill pid }
    end

    private

    def raise_if_terminated!
      if @____terminated
        raise TerminatedError.new "Process #{@____pid} has been terminated!"
      end
    end

    def self.kill(pid, timeout = 0.2)
      begin
        Timeout.timeout(timeout) do
          Actor.send_signal(pid, 'SIGKILL')
        end
      rescue Timeout::Error
        Process.detach pid
      end
    end

    def self.send_signal(pid, signal)
      begin
        Process.kill signal, pid
        Process.wait pid
      rescue SystemCallError
      end
    end

    def self.spawn(obj, request_channel, response_channel)
      pid = fork do
        termination_requested = false
        trap :SIGTERM do
          termination_requested = true
        end
        loop do
          if request_channel.readable?
            msg = request_channel.get
            begin
              method = obj.method("____#{msg[:name]}")
              if msg[:block_given]
                response = method.call *msg[:args] do |yielded|
                  response_channel.put id: msg[:id], type: :yield, value: yielded
                end
              else
                response = method.call *msg[:args]
              end
            rescue Exception => e
              response = e
            end
            if msg[:respond]
              response_channel.put id: msg[:id], type: :return, value: response
            end
          elsif termination_requested
            break
          else
            # wait a little before trying again
            sleep 0.1
          end
        end
      end
      at_exit do
        self.kill(pid)
      end
      pid
    end

    def self.method_added(name)
      @added_methods ||= []
      return if @added_methods.include? name.to_s
      @added_methods += [name.to_s, "____#{name}", "____#{name}_async", "____#{name}_future"]

      original_method = instance_method(name)

      # original method is moved to ____name
      define_method("____#{name}") do |*args, &block|
        original_method.bind(self).call(*args, &block)
      end

      # async (tell)
      define_method("____#{name}_async") do |*args, &block|
        id = SecureRandom.uuid
        if block
          raise UnsupportedError.new "Cannot do asynchronous call when providing a block!"
        end
        @____request_channel.put id: id, respond: false, name: name, args: args, block_given: false
        nil
      end

      # future (ask)
      define_method("____#{name}_future") do |*args, &block|
        id = SecureRandom.uuid
        @____request_channel.put id: id, respond: true, name: name, args: args, block_given: !block.nil?
        @____response_handler.register_block(id, block) if block
        Future.new(@____response_handler, id)
      end
      ask = instance_method("____#{name}_future")

      # original method or blocking call
      # direct call or via channel depending on who is calling
      define_method(name) do |*args, &block|
        raise_if_terminated!
        if @____pid # called from outside probject
          ask.bind(self).call(*args, &block).get!
        else # called from the probject itself
          original_method.bind(self).call(*args, &block)
        end
      end
    end
  end
end