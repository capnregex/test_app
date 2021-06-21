require 'rails_helper'

RSpec.describe IntervalType do
  subject(:type) { IntervalType.new }

  describe ".cast" do
    result = type.cast("P1DT2H15M")
    binding.pry
  end
end
