require "helper"
require "fluent/plugin/out_aliyunoss.rb"

class AliyunossOutputTest < Test::Unit::TestCase
  setup do
    Fluent::Test.setup
  end

  test "failure" do
    flunk
  end

  private

  def create_driver(conf)
    Fluent::Test::Driver::Output.new(Fluent::Plugin::AliyunossOutput).configure(conf)
  end
end
