# frozen_string_literal: true

module Tasks
  class CreateService
    attr_reader :task, :errors

    def initialize(params)
      @params = params
      @task = nil
      @errors = []
    end

    def call
      @task = Task.create(normalized_params)
      success?
    end

    def success?
      @task.persisted?
    end

    private

    def normalized_params
      {
        name: @params[:name],
        explanation: @params[:explanation],
        status: @params[:status],
        priority: normalize_priority(@params[:priority]),
        genre_id: @params[:genreId],
        deadline_date: @params[:deadlineDate]
      }.compact
    end

    def normalize_priority(priority)
      return nil if priority.blank?
      priority.to_i
    end
  end
end
