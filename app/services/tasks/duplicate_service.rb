# frozen_string_literal: true

module Tasks
  class DuplicateService
    attr_reader :duplicated_task

    def initialize(task_id)
      @task_id = task_id
      @duplicated_task = nil
    end

    def call
      original_task = find_original_task
      return false unless original_task

      @duplicated_task = build_duplicated_task(original_task)
      @duplicated_task.save
    end

    def success?
      @duplicated_task&.persisted? || false
    end

    private

    def find_original_task
      Task.find_by(id: @task_id)
    end

    def build_duplicated_task(original_task)
      Task.new(duplicated_attributes(original_task))
    end

    def duplicated_attributes(original_task)
      {
        name: duplicate_name(original_task.name),
        explanation: original_task.explanation,
        genre_id: original_task.genre_id,
        priority: original_task.priority,
        status: initial_status,
        deadline_date: initial_deadline_date
      }
    end

    def duplicate_name(original_name)
      "#{original_name}(コピー)"
    end

    def initial_status
      0
    end

    def initial_deadline_date
      nil
    end
  end
end
