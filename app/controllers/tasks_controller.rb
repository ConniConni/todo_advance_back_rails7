class TasksController < ApplicationController
  before_action :select_task, only: [:update, :destroy, :update_status]
  skip_before_action :verify_authenticity_token

  def index
    tasks_all
  end

  def create
    service = Tasks::CreateService.new(create_params)
    service.call
    @result = service.task
    tasks_all
  end

  def update
    @task.update(task_params)
    tasks_all
  end

  def destroy
    @task.destroy
    tasks_all
  end

  def update_status
    @task.update(status: params[:status])
    tasks_all
  end

  def duplicate
    service = Tasks::DuplicateService.new(params[:id])

    if service.call
      tasks_all
    else
      render json: { error: 'Task not found' }, status: :not_found
    end
  end

  def stats
    service = Tasks::StatsService.new
    service.call
    @stats = service.result
    render :stats
  end

  def report
    service = Tasks::ReportService.new
    service.call
    @report = service.result
    render :report
  end

  private

  def create_params
    params.permit(:name, :explanation, :status, :priority, :genreId, :deadlineDate)
  end

  def task_params
    permitted = params.permit(:name, :explanation, :status, :priority)
    permitted[:priority] = permitted[:priority].to_i if permitted[:priority].present?
    permitted[:genre_id] = params[:genreId] if params[:genreId].present?
    permitted[:deadline_date] = params[:deadlineDate] if params[:deadlineDate].present?
    permitted
  end

  def select_task
    @task = Task.find(params[:id])
  end

  def tasks_all
    @tasks = Task.all
    render :all_tasks
  end
end
