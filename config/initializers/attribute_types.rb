# ActiveRecord::Type.register(:interval, IntervalType, adapter: :postgresql, override: true)
ActiveRecord::Type.register(:interval, IntervalType, override: true)
# ActiveRecord::Type.register(:interval, IntervalType, adapter: :postgresql)
ActiveModel::Type.register(:interval, IntervalType)
