require 'rails_helper'

RSpec.describe IntervalType do
  subject(:interval_type) { IntervalType.new }
  let(:iso) { "P2Y3M1DT2H15M5S" }
  let(:parts) { { days: 1, hours: 2, minutes: 15, months: 3, seconds: 5, years: 2 } }
  let(:pg_verbose) { "2 years 3 months 1 day 2 hours 15 minutes 5 seconds" }
  let(:seconds) { 71097647 }
  let(:duration) { ActiveSupport::Duration.build(seconds) }

  describe ".cast" do
    it "nil" do
      result = interval_type.cast(nil)
      expect(result).to be_nil
    end
    it "duration" do
      expect(duration.parts).to eq(parts)
      expect(duration.to_i).to eq(seconds)
      expect(duration.iso8601).to eq(iso)
      result = interval_type.cast(duration)
      expect(result).to eq(duration)
    end
    it "iso" do
      result = interval_type.cast(iso)
      expect(result.parts).to eq(parts)
      expect(result.to_i).to eq(seconds)
      expect(result.iso8601).to eq(iso)
    end
    it "seconds" do
      result = interval_type.cast(seconds)
      expect(result.parts).to eq(parts)
      expect(result.to_i).to eq(seconds)
      expect(result.iso8601).to eq(iso)
    end
    it "parts" do
      result = interval_type.cast(parts)
      expect(result.parts).to eq(parts)
      expect(result.to_i).to eq(seconds)
      expect(result.iso8601).to eq(iso)
    end
    it "postgresql verbose" do
      result = interval_type.cast(pg_verbose)
      expect(result.parts).to eq(parts)
      expect(result.to_i).to eq(seconds)
      expect(result.iso8601).to eq(iso)
    end
  end
end
