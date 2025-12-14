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

  describe 'POST /tasks/:id/duplicate' do
    # ========================================
    # 正常系
    # ========================================
    context '正常なリクエスト' do
      let!(:original_task) do
        Task.create!(
          name: 'オリジナルタスク',
          explanation: 'これはテストタスクです',
          genre: genre,
          priority: :high,
          status: 5,  # 完了状態
          deadline_date: '2025-12-31'
        )
      end

      it 'タスクが複製され、レコードが1件増えること' do
        expect {
          post "/tasks/#{original_task.id}/duplicate"
        }.to change(Task, :count).by(1)
      end

      it 'ステータスコード200が返されること' do
        post "/tasks/#{original_task.id}/duplicate"
        expect(response).to have_http_status(:success)
      end

      it 'レスポンスに複製されたタスクが含まれること' do
        post "/tasks/#{original_task.id}/duplicate"

        json_response = JSON.parse(response.body)
        duplicated_task = json_response.find { |task| task['name'] == 'オリジナルタスク(コピー)' }

        expect(duplicated_task).not_to be_nil
      end

      it 'nameに「(コピー)」が含まれること' do
        post "/tasks/#{original_task.id}/duplicate"

        json_response = JSON.parse(response.body)
        duplicated_task = json_response.find { |task| task['name'] == 'オリジナルタスク(コピー)' }

        expect(duplicated_task['name']).to eq('オリジナルタスク(コピー)')
      end

      it 'statusが初期ステータスになること' do
        post "/tasks/#{original_task.id}/duplicate"

        json_response = JSON.parse(response.body)
        duplicated_task = json_response.find { |task| task['name'] == 'オリジナルタスク(コピー)' }

        # 元のタスクはstatus=5だが、複製後は初期ステータス（0 or 1）になる
        expect(duplicated_task['status']).to eq(0).or eq(1)
        expect(duplicated_task['status']).not_to eq(5)
      end

      it 'deadline_dateがnullになること' do
        post "/tasks/#{original_task.id}/duplicate"

        json_response = JSON.parse(response.body)
        duplicated_task = json_response.find { |task| task['name'] == 'オリジナルタスク(コピー)' }

        expect(duplicated_task['deadlineDate']).to be_nil
      end

      it 'explanation, genre_id, priorityが引き継がれること' do
        post "/tasks/#{original_task.id}/duplicate"

        json_response = JSON.parse(response.body)
        duplicated_task = json_response.find { |task| task['name'] == 'オリジナルタスク(コピー)' }

        expect(duplicated_task['explanation']).to eq('これはテストタスクです')
        expect(duplicated_task['genreId']).to eq(genre.id)
        expect(duplicated_task['priority']).to eq(2)  # high
      end

      it '元のタスクが変更されていないこと' do
        original_attributes = original_task.attributes.dup

        post "/tasks/#{original_task.id}/duplicate"

        original_task.reload
        expect(original_task.name).to eq(original_attributes['name'])
        expect(original_task.status).to eq(original_attributes['status'])
        expect(original_task.deadline_date.to_s).to eq(original_attributes['deadline_date'].to_s)
      end
    end

    # ========================================
    # 異常系
    # ========================================
    context '存在しないIDを指定した場合' do
      it 'ステータスコード404が返されること' do
        post '/tasks/99999/duplicate'
        expect(response).to have_http_status(:not_found)
      end

      it '適切なエラーメッセージが返されること' do
        post '/tasks/99999/duplicate'

        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('error')
        expect(json_response['error']).to be_present
      end

      it 'タスクが作成されないこと' do
        expect {
          post '/tasks/99999/duplicate'
        }.not_to change(Task, :count)
      end
    end

    context '不正なIDフォーマットを指定した場合' do
      it 'ステータスコード404または400が返されること' do
        post '/tasks/invalid_id/duplicate'
        expect(response).to have_http_status(:not_found).or have_http_status(:bad_request)
      end

      it 'タスクが作成されないこと' do
        expect {
          post '/tasks/invalid_id/duplicate'
        }.not_to change(Task, :count)
      end
    end
  end

  describe 'GET /tasks/stats' do
    context 'タスクが存在する場合' do
      before do
        # status: 0 - 2件
        Task.create!(name: 'タスク1', genre: genre, status: 0, priority: :low)
        Task.create!(name: 'タスク2', genre: genre, status: 0, priority: :medium)

        # status: 1 - 1件
        Task.create!(name: 'タスク3', genre: genre, status: 1, priority: :high)

        # status: 5 (完了) - 2件
        Task.create!(name: 'タスク4', genre: genre, status: 5, priority: :medium)
        Task.create!(name: 'タスク5', genre: genre, status: 5, priority: :high)
      end

      it 'ステータスコード200が返されること' do
        get '/tasks/stats'
        expect(response).to have_http_status(:success)
      end

      it 'レスポンスにtotalCountが含まれること' do
        get '/tasks/stats'

        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('totalCount')
        expect(json_response['totalCount']).to eq(5)
      end

      it 'レスポンスにstatusCountsが含まれること' do
        get '/tasks/stats'

        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('statusCounts')
        expect(json_response['statusCounts']).to be_a(Hash)
        expect(json_response['statusCounts']['0']).to eq(2)
        expect(json_response['statusCounts']['1']).to eq(1)
        expect(json_response['statusCounts']['5']).to eq(2)
      end

      it 'レスポンスにcompletionRateが含まれること' do
        get '/tasks/stats'

        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('completionRate')
        expect(json_response['completionRate']).to be_within(0.01).of(40.0)
      end
    end

    context 'タスクが0件の場合' do
      it 'ステータスコード200が返されること' do
        get '/tasks/stats'
        expect(response).to have_http_status(:success)
      end

      it 'totalCountが0であること' do
        get '/tasks/stats'

        json_response = JSON.parse(response.body)
        expect(json_response['totalCount']).to eq(0)
      end

      it 'statusCountsが空のオブジェクトであること' do
        get '/tasks/stats'

        json_response = JSON.parse(response.body)
        expect(json_response['statusCounts']).to eq({})
      end

      it 'completionRateが0.0であること' do
        get '/tasks/stats'

        json_response = JSON.parse(response.body)
        expect(json_response['completionRate']).to eq(0.0)
      end
    end
  end

  describe 'GET /tasks/report' do
    context 'タスクが存在する場合' do
      before do
        # not_started: 2件
        Task.create!(name: 'タスク1', genre: genre, status: :not_started, priority: :low)
        Task.create!(name: 'タスク2', genre: genre, status: :not_started, priority: :medium)

        # in_progress: 1件
        Task.create!(name: 'タスク3', genre: genre, status: :in_progress, priority: :high)

        # completed: 2件
        Task.create!(name: 'タスク4', genre: genre, status: :completed, priority: :medium)
        Task.create!(name: 'タスク5', genre: genre, status: :completed, priority: :high)
      end

      it 'ステータスコード200が返されること' do
        get '/tasks/report'
        expect(response).to have_http_status(:success)
      end

      it 'レスポンスにtotalCountが含まれること' do
        get '/tasks/report'

        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('totalCount')
        expect(json_response['totalCount']).to eq(5)
      end

      it 'レスポンスにcountByStatusが含まれること' do
        get '/tasks/report'

        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('countByStatus')
        expect(json_response['countByStatus']).to be_a(Hash)
        expect(json_response['countByStatus']['notStarted']).to eq(2)
        expect(json_response['countByStatus']['inProgress']).to eq(1)
        expect(json_response['countByStatus']['completed']).to eq(2)
      end

      it 'レスポンスにcompletionRateが含まれること' do
        get '/tasks/report'

        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('completionRate')
        expect(json_response['completionRate']).to eq(40.0)
      end
    end

    context 'タスクが0件の場合' do
      it 'ステータスコード200が返されること' do
        get '/tasks/report'
        expect(response).to have_http_status(:success)
      end

      it 'totalCountが0であること' do
        get '/tasks/report'

        json_response = JSON.parse(response.body)
        expect(json_response['totalCount']).to eq(0)
      end

      it 'countByStatusの各ステータスが0であること' do
        get '/tasks/report'

        json_response = JSON.parse(response.body)
        expect(json_response['countByStatus']['notStarted']).to eq(0)
        expect(json_response['countByStatus']['inProgress']).to eq(0)
        expect(json_response['countByStatus']['completed']).to eq(0)
      end

      it 'completionRateが0.0であること' do
        get '/tasks/report'

        json_response = JSON.parse(response.body)
        expect(json_response['completionRate']).to eq(0.0)
      end
    end

    context '完了率が小数点以下1桁で表示される場合' do
      before do
        # 3件中1件完了 -> 33.3%
        Task.create!(name: 'タスク1', genre: genre, status: :not_started, priority: :low)
        Task.create!(name: 'タスク2', genre: genre, status: :not_started, priority: :medium)
        Task.create!(name: 'タスク3', genre: genre, status: :completed, priority: :high)
      end

      it '完了率が小数点以下1桁で計算されること' do
        get '/tasks/report'

        json_response = JSON.parse(response.body)
        expect(json_response['completionRate']).to eq(33.3)
      end
    end
  end
end
