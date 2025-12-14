# frozen_string_literal: true

module Tasks
  class ReportService
    attr_reader :result

    def initialize
      @result = nil
    end

    def call
      @result = calculate_report
    end

    private

    def calculate_report
      {
        total_count: total_count,
        count_by_status: count_by_status,
        completion_rate: completion_rate
      }
    end

    def total_count
      Task.count
    end

    def count_by_status
      {
        not_started: Task.not_started.count,
        in_progress: Task.in_progress.count,
        completed: Task.completed.count
      }
    end

    def completion_rate
      return 0.0 if total_count.zero?

      completed_count = Task.completed.count
      (completed_count.to_f / total_count * 100).round(1)
    end
  end
end
