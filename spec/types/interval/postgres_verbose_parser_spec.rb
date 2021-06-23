require 'rails_helper'

RSpec.describe Interval::PostgresVerboseParser do
  let(:value) { |meta| meta.description }
  let(:parser) { described_class.new(value) }
  let(:parts) { {  } }
  let(:pg_verbose) { "2 years 3 months 1 day 2 hours 15 minutes 5 seconds" }
  subject(:result) { parser.parse! }

  it "2 years" do
    expect(result).to eq(years: 2)
  end

  it "2 years 3 months 1 day 2 hours 15 minutes 5.4 seconds" do
    expect(result).to eq(days: 1, hours: 2, minutes: 15, months: 3, seconds: 5.4, years: 2)
  end

  it "2-3" do
    expect(result).to eq(years: 2, months: 3)
  end

  it "2-3 4" do
    expect(result).to eq(years: 2, months: 3, seconds: 4)
  end

  it "2:3:4.5" do
    expect(result).to eq(hours: 2, minutes: 3, seconds: 4.5)
  end

  it '1 3:2' do
    expect(result).to eq(days: 1, hours: 3, minutes: 2)
  end

  it '1-2 -3 -4:5:6.7' do
    expect(result).to eq(years: 1, months: 2, days: -3, hours: -4, minutes: -5, seconds: -6.7)
  end

  it '1-2 3 4:5:6.7 ago' do
    expect(result).to eq(years: -1, months: -2, days: -3, hours: -4, minutes: -5, seconds: -6.7)
  end

  it '1 year 2 months 3 4:5:6.7 ago' do
    expect(result).to eq(years: -1, months: -2, days: -3, hours: -4, minutes: -5, seconds: -6.7)
  end

  it '1-2 3:4' do
    expect(result).to eq(years: 1, months: 2, hours: 3, minutes: 4)
  end

  it '3:4 1-2' do
    expect(result).to eq(years: 1, months: 2, hours: 3, minutes: 4)
  end

  it "1" do
    expect(result).to eq(seconds: 1)
  end

  it "-3.5" do
    expect(result).to eq(seconds: -3.5)
  end

  it "3:2.1" do
    expect(result).to eq(minutes: 3, seconds: 2.1)
  end

  it "4:3:2.1" do
    expect(result).to eq(hours: 4, minutes: 3, seconds: 2.1)
  end

  it "4:3" do
    expect(result).to eq(hours: 4, minutes: 3)
  end
end
