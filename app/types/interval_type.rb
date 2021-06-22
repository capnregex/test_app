class IntervalType < ActiveModel::Type::Value
  # Converts a value from user input to the appropriate ruby type
  def cast(value)
    return nil unless value.present?

    cast_value(value)
  end

  # Converts a value from database input to the appropriate ruby type
  def deserialize(value)
    cast(value)
  end

  # Returns true if this type can convert value to a type that is usable by the database.
  def serializable?(value)
    case value
    when ActiveSupport::Duration 
      true
    else
      false
    end
  end

  # Casts a value from the ruby type to a type that the database knows how to understand.
  def serialize(value)
    case value
    when ActiveSupport::Duration 
      value.iso8601
    end
  end 

  protected

  POSTGRES_VERBOSE = /(?<part>(?<qty>[+-]?\d)\s*(?<unit>\w+)\s*)*?(ago)?/

  def cast_postgres_verbose(value)
    result = POSTGRES_VERBOSE.match(value)
    binding.pry
  end

  def cast_iso8601(value)
    ActiveSupport::Duration.parse(value) 
  rescue ActiveSupport::Duration::ISO8601Parser::ParsingError => e
    cast_postgres_verbose(value)
  end

  def cast_parts(value)
    parts = value.slice(*ActiveSupport::Duration::PARTS)
    seconds = ActiveSupport::Duration.send(:calculate_total_seconds, parts)
    ActiveSupport::Duration.new(seconds, parts)
  end

  def cast_value(value)
    case value
    when Numeric
      ActiveSupport::Duration.build(value)
    when ActiveSupport::Duration 
      value
    when Hash
      cast_parts(value)
    when String
      cast_iso8601(value)
    else
      nil
    end
  end

end
