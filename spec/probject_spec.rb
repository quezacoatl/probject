require 'rspec'

require_relative '../lib/probject'

describe Probject::Actor do

  before(:all) do
    class SubProbject < Probject::Actor
      attr_accessor :text

      def say_hi
        "Hi!"
      end

      def greet
        "#{say_hi} How are you doing?"
      end

      def sleep_and_return(value = nil)
        sleep 1
        value
      end

      def using_block
        yield "Hello block!"
        yield "2"
        yield "3"
      end
    end
    @probject = SubProbject.new
  end

  def count_processes
    Integer(`ps -ef | grep #{Process.pid} | grep -c -v grep`)
  end

  it "starts a child process" do
    count_processes.should == 2
    @probject.pid.should > Process.pid
  end

  it "handles simple method calls" do
    @probject.say_hi.should == "Hi!"
  end

  it "can also use blocks" do
    yielded = []
    @probject.using_block do |y|
      yielded << y
    end
    yielded.shift.should == "Hello block!"
    yielded.shift.should == "2"
    yielded.shift.should == "3"
  end

  it "handles method calls which invokes another method on self" do
    @probject.greet.should == "Hi! How are you doing?"
  end

  context "sync" do
    it "will block until response is received" do
      @probject.sleep_and_return('test').should == 'test'
    end
  end

  describe "#async" do
    it "returns nil for asyncrhonous invocations" do
      @probject.async.say_hi.should == nil
    end

    it "will not block" do
      start = Time.now
      @probject.async.sleep_and_return
      (Time.now - start).should < 0.1
    end

    it "works to set attributes" do
      @probject.async.text = '123'
      @probject.text.should == '123'
    end
  end

  describe "#future" do
    it "knows if it is done" do
      future = @probject.future.sleep_and_return
      future.done?.should == false
      sleep 1.1
      future.done?.should == true
    end

    it "can block until it is done" do
      @probject.future.sleep_and_return('test').get.should == 'test'
    end

    it "works to have several futures" do
      a = @probject.future.sleep_and_return('a')
      b = @probject.future.sleep_and_return('b')
      c = @probject.future.sleep_and_return('c')
      b.get.should == 'b'
      c.get.should == 'c'
      a.get.should == 'a'
    end
  end

  context "terminated probject" do

    before do
      @probject = SubProbject.new
      count_processes.should == 3 # yet another probject has been created here
      @probject.terminate
    end

    it "terminated the child process" do
      count_processes.should == 2
    end

    it "will raise exception on calls after terminated" do
      expect {@probject.async.say_hi}.to raise_error Probject::TerminatedError
    end

    describe "#terminated?" do
      it "returns true if probject has been terminated" do
        @probject.terminated?.should == true
      end
    end
  end
end