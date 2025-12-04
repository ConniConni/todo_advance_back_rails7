require 'rails_helper'

RSpec.describe 'Tasks API', type: :request do
  let(:genre) { Genre.create!(name: 'テストジャンル') }

  describe 'POST /tasks' do
    context 'priorityパラメータを指定した場合' do
      it 'タスクを作成できること' do
        task_params = {
          name: 'テストタスク',
          explanation: 'テストの説明',
          genreId: genre.id,
          deadlineDate: '2025-12-31',
          status: 0,
          priority: 2  # high
        }

        expect {
          post '/tasks', params: task_params
        }.to change(Task, :count).by(1)

        expect(response).to have_http_status(:success)
      end

      it 'レスポンスJSONに作成されたタスクのpriorityが含まれていること' do
        task_params = {
          name: 'テストタスク',
          explanation: 'テストの説明',
          genreId: genre.id,
          deadlineDate: '2025-12-31',
          status: 0,
          priority: 2  # high
        }

        post '/tasks', params: task_params

        json_response = JSON.parse(response.body)
        created_task = json_response.find { |task| task['name'] == 'テストタスク' }

        expect(created_task).not_to be_nil
        expect(created_task['priority']).to eq(2)
      end

      it '優先度が「低」のタスクを作成できること' do
        task_params = {
          name: '低優先度タスク',
          explanation: 'テストの説明',
          genreId: genre.id,
          priority: 0  # low
        }

        post '/tasks', params: task_params
        json_response = JSON.parse(response.body)
        created_task = json_response.find { |task| task['name'] == '低優先度タスク' }

        expect(created_task['priority']).to eq(0)
      end

      it '優先度が「中」のタスクを作成できること' do
        task_params = {
          name: '中優先度タスク',
          explanation: 'テストの説明',
          genreId: genre.id,
          priority: 1  # medium
        }

        post '/tasks', params: task_params
        json_response = JSON.parse(response.body)
        created_task = json_response.find { |task| task['name'] == '中優先度タスク' }

        expect(created_task['priority']).to eq(1)
      end

      it '優先度が「高」のタスクを作成できること' do
        task_params = {
          name: '高優先度タスク',
          explanation: 'テストの説明',
          genreId: genre.id,
          priority: 2  # high
        }

        post '/tasks', params: task_params
        json_response = JSON.parse(response.body)
        created_task = json_response.find { |task| task['name'] == '高優先度タスク' }

        expect(created_task['priority']).to eq(2)
      end
    end

    context 'priorityパラメータを指定しない場合' do
      it 'デフォルト値「中」でタスクを作成できること' do
        task_params = {
          name: 'デフォルト優先度タスク',
          explanation: 'テストの説明',
          genreId: genre.id
        }

        post '/tasks', params: task_params
        json_response = JSON.parse(response.body)
        created_task = json_response.find { |task| task['name'] == 'デフォルト優先度タスク' }

        expect(created_task['priority']).to eq(1)  # medium
      end
    end
  end

  describe 'GET /tasks' do
    before do
      Task.create!(name: '低優先度タスク', genre: genre, priority: :low)
      Task.create!(name: '中優先度タスク', genre: genre, priority: :medium)
      Task.create!(name: '高優先度タスク', genre: genre, priority: :high)
    end

    it 'すべてのタスクのpriorityが含まれていること' do
      get '/tasks'

      json_response = JSON.parse(response.body)

      expect(json_response).to be_an(Array)
      expect(json_response.length).to eq(3)

      json_response.each do |task|
        expect(task).to have_key('priority')
        expect(task['priority']).to be_between(0, 2)
      end
    end
  end

  describe 'PATCH /tasks/:id' do
    let(:task) { Task.create!(name: 'テストタスク', genre: genre, priority: :low) }

    it 'タスクの優先度を更新できること' do
      patch "/tasks/#{task.id}", params: { priority: 2 }  # high

      json_response = JSON.parse(response.body)
      updated_task = json_response.find { |t| t['id'] == task.id }

      expect(updated_task['priority']).to eq(2)
      expect(task.reload.priority).to eq('high')
    end
  end
end
