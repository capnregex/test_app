# frozen_string_literal: true

require "strscan"

# Parses a string formatted according to postgresql verbose interval format into the hash.
#
# See https://www.postgresql.org/docs/9.5/datatype-datetime.html#DATATYPE-INTERVAL-INPUT
#
# This parser allows negative parts to be present in pattern.
class  Interval::PostgresVerboseParser # :nodoc:
  class ParsingError < ::ArgumentError; end

  PERIOD_OR_COMMA = /\.|,/
  PERIOD = "."
  COMMA = ","
  BLANK = /\s*/

  ISO_P = /p/
  ISO_T = /t/
  ISO_VALUE_YMWD = /([+\-]?\d+(?:[.,]\d+)?)([ymwd])/
  ISO_ALT_YMD = /(\d+)(?:-(\d+)(?:-(\d+))?)?/
  ISO_VALUE_HMS = /([+\-]?\d+(?:[.,]\d+)?)([hms])/
  ISO_ALT_HMS = /(-?\d+(?:[.,]\d+)?)(?::(-?\d+(?:[.,]\d+)?)(?::(-?\d+(?:[.,]\d+)?))?)?/
  ISO_YMWD = { 'y' => 'year', 'm' => 'month', 'w' => 'week', 'd' => 'day' }
  ISO_HMS = { 'h' => 'hour', 'm' => 'minute', 's' => 'second' }

  SQL_AT = /@\s*/
  SQL_YM = /(\d+)-(\d+)\s*/
  SQL_DHMS = /(?:([+-]?\d+)\s+)?([+-])?(?:(\d+):)?(?:(\d+):)?(\d+(?:[.,]\d+)?)\s*/
  SQL_VERBOSE = /([+\-]?\d+(?:[.,]\d+)?)\s*([a-z]+)\s*/
  SQL_AGO = /ago/
    
  SQL_UNITS = {
    'micro' => 'microsecond',
    'milli' => 'millisecond',
    's' => 'second',
    'sec' => 'second',
    'm' => 'minute',
    'min' => 'minute',
    'h' => 'hour',
    'd' => 'day',
    'w' => 'week',
    'mon' => 'month',
    'y' => 'year'
  }

  UNITS = {
    'microsecond' => { part: :seconds, multiplier: 0.000001 },
    'millisecond' => { part: :seconds, multiplier: 0.001 },
    'second' => { part: :seconds, multiplier: 1 },
    'minute' => { part: :minutes, multiplier: 1 },
    'hour' => { part: :hours, multiplier: 1 },
    'day' => { part: :days, multiplier: 1 },
    'week' => { part: :days, multiplier: 7 },
    'month' => { part: :months, multiplier: 1 },
    'year' => { part: :years, multiplier: 1 },
    'decade' => { part: :years, multiplier: 10 },
    'century' => { part: :years, multiplier: 100 },
    'millennium' => { part: :years, multiplier: 1000 }
  }

  attr_reader :parts, :scanner
  delegate :string, :scan, :eos?, to: :scanner

  def initialize(string)
    @scanner = StringScanner.new(string.downcase.strip)
    @parts = Hash.new(0)
  end

  def parse!
    if scan(ISO_P) # iso 8601
      scan_iso_days
      scan_iso_time if scan(ISO_T) # time part
    else
      scan_sql
    end

    parts
  end

  private

  def scan_iso_days
    while scan(ISO_VALUE_YMWD) # day format with designators
      add(value_of(scanner[1]), ISO_YMWD[scanner[2]])
    end
    if scan(ISO_ALT_YMD)
      add(value_of(scanner[1]), 'years')
      add(value_of(scanner[2]), 'months')
      add(value_of(scanner[3]), 'days')
    end
  end

  def scan_iso_time
    while scan(ISO_VALUE_HMS) # day format with designators
      add(value_of(scanner[1]), ISO_HMS[scanner[2]])
    end
    if scan(ISO_ALT_HMS)
      add(value_of(scanner[1]), 'hours')
      add(value_of(scanner[2]), 'minutes')
      add(value_of(scanner[3]), 'seconds')
    end
  end

  def scan_sql
    scan(SQL_AT)
    until eos?
      if scan(SQL_VERBOSE) # traditional postgresql verbose format
        add(value_of(scanner[1]), sql_unit(scanner[2]))
      elsif scan(SQL_YM)
        add(value_of(scanner[1]), 'years')
        add(value_of(scanner[2]), 'months')
      elsif scan(SQL_DHMS)
        add_sql_dhms(scanner[1], scanner[2], scanner[3], scanner[4], scanner[5])
      elsif scan(SQL_AGO)
        invert_parts
      else
        binding.pry
        raise_parsing_error("Unknown format")
      end
    end
  end

  def add_sql_dhms(days,sign,hours,minutes,seconds)
    add(value_of(days), 'days') if days
    if hours && minutes.nil?
      if PERIOD_OR_COMMA.match? seconds # minutes:seconds
        minutes = hours
        hours = nil
      else # hours:minutes
        minutes = seconds
        seconds = nil
      end
    end
    add(value_of("#{sign}#{hours}"), 'hours') if hours
    add(value_of("#{sign}#{minutes}"), 'minutes') if minutes
    add(value_of("#{sign}#{seconds}"), 'seconds') if seconds
  end

  def invert_parts
    parts.transform_values! { |value| value * -1 }
  end

  def value_of(quantity)
    if PERIOD_OR_COMMA.match? quantity
      quantity.tr(COMMA,PERIOD).to_f
    else
      quantity.to_i
    end
  end

  def sql_unit(unit)
    unit = unit.singularize
    SQL_UNITS[unit] || unit
  end

  def add(quantity, unit)
    return unless quantity && unit
    unit = unit.singularize
    args = UNITS[unit] || {}
    part = args[:part] || unit.pluralize.to_sym
    multiplier = args[:multiplier] || 1

    @parts[part] += quantity * multiplier
  end

  def raise_parsing_error(reason = nil)
    raise ParsingError, "Invalid Verbose Interval: #{scanner.string.inspect} #{reason}".strip
  end
end

