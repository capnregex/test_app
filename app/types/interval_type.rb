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

  def cast_iso8601(value)
    ActiveSupport::Duration.parse(value) 
  rescue ActiveSupport::Duration::ISO8601Parser::ParsingError => e
    nil
  end

  def cast_value(value)
    case value
    when ActiveSupport::Duration 
      value
    when String
      cast_iso8601(value)
    end
  end

end
