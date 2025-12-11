# frozen_string_literal: true

module Tasks
  class StatsService
    COMPLETED_STATUS = 5

    attr_reader :result

    def initialize
      @result = nil
    end

    def call
      @result = calculate_stats
    end

    private

    def calculate_stats
      {
        total_count: total_count,
        status_counts: status_counts,
        completion_rate: completion_rate
      }
    end

    def total_count
      Task.count
    end

    def status_counts
      Task.group(:status).count
    end

    def completion_rate
      return 0.0 if total_count.zero?

      completed_count = Task.where(status: COMPLETED_STATUS).count
      (completed_count.to_f / total_count * 100).round(2)
    end
  end
end
