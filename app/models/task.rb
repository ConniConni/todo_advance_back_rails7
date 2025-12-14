class Task < ApplicationRecord
  belongs_to :genre

  enum priority: { low: 0, medium: 1, high: 2 }
  enum status: { not_started: 0, in_progress: 1, completed: 5 }
end
