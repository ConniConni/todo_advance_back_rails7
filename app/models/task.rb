class Task < ApplicationRecord
  belongs_to :genre

  enum priority: { low: 0, medium: 1, high: 2 }
end
