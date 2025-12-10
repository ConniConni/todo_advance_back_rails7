require 'rails_helper'

RSpec.describe Tasks::DuplicateService do
  let(:genre) { Genre.create!(name: 'テストジャンル') }

  describe '#call' do
    # ========================================
    # 正常系 - 基本的な複製動作（1〜5）
    # ========================================
    context '正常な複製処理' do
      let!(:original_task) do
        Task.create!(
          name: 'オリジナルタスク',
          explanation: 'これはテストタスクです',
          genre: genre,
          priority: :medium,
          status: 1,
          deadline_date: '2025-12-31'
        )
      end

      it '複製されたタスクが作成される' do
        expect {
          Tasks::DuplicateService.new(original_task.id).call
        }.to change(Task, :count).by(1)
      end

      it 'nameの末尾に「(コピー)」が追加される' do
        service = Tasks::DuplicateService.new(original_task.id)
        service.call
        expect(service.duplicated_task.name).to eq('オリジナルタスク(コピー)')
      end

      it 'explanationが正しくコピーされる' do
        service = Tasks::DuplicateService.new(original_task.id)
        service.call
        expect(service.duplicated_task.explanation).to eq('これはテストタスクです')
      end

      it 'genre_idが正しくコピーされる' do
        service = Tasks::DuplicateService.new(original_task.id)
        service.call
        expect(service.duplicated_task.genre_id).to eq(genre.id)
      end

      it 'priorityが正しくコピーされる' do
        service = Tasks::DuplicateService.new(original_task.id)
        service.call
        expect(service.duplicated_task.priority).to eq('medium')
      end

      it 'trueを返す' do
        service = Tasks::DuplicateService.new(original_task.id)
        expect(service.call).to be true
      end

      it 'success?がtrueを返す' do
        service = Tasks::DuplicateService.new(original_task.id)
        service.call
        expect(service.success?).to be true
      end
    end

    # ========================================
    # 正常系 - 特別な処理（6〜8）
    # ========================================
    context 'statusの処理' do
      it '元のタスクのstatusに関わらず、複製後は初期ステータスになる' do
        # status=5（完了など）のタスクを作成
        task_with_status = Task.create!(
          name: '完了済みタスク',
          genre: genre,
          status: 5,
          priority: :high
        )

        service = Tasks::DuplicateService.new(task_with_status.id)
        service.call

        # 複製後のstatusが初期値（0 or 1など）になることを確認
        # Taskモデルのデフォルト値に依存するため、初期値を確認
        expect(service.duplicated_task.status).to eq(0).or eq(1)
        expect(service.duplicated_task.status).not_to eq(5)
      end

      it '様々なstatusを持つタスクが正しく初期化される' do
        [0, 1, 2, 3, 4, 5].each do |status_value|
          task = Task.create!(
            name: "ステータス#{status_value}のタスク",
            genre: genre,
            status: status_value,
            priority: :low
          )

          service = Tasks::DuplicateService.new(task.id)
          service.call

          expect(service.duplicated_task.status).to eq(0).or eq(1)
        end
      end
    end

    context 'deadline_dateの処理' do
      it '元のタスクにdeadline_dateが設定されていても、複製後はnilになる' do
        task_with_deadline = Task.create!(
          name: '期限付きタスク',
          genre: genre,
          deadline_date: '2025-12-31',
          priority: :medium
        )

        service = Tasks::DuplicateService.new(task_with_deadline.id)
        service.call

        expect(service.duplicated_task.deadline_date).to be_nil
      end
    end

    context '元のタスクの不変性' do
      it '複製元のタスクの各属性が変更されない' do
        original_task = Task.create!(
          name: '元タスク',
          explanation: '元の説明',
          genre: genre,
          priority: :high,
          status: 3,
          deadline_date: '2025-11-30'
        )

        original_attributes = original_task.attributes.dup

        service = Tasks::DuplicateService.new(original_task.id)
        service.call

        original_task.reload
        expect(original_task.name).to eq(original_attributes['name'])
        expect(original_task.explanation).to eq(original_attributes['explanation'])
        expect(original_task.status).to eq(original_attributes['status'])
        expect(original_task.priority).to eq(original_attributes['priority'])
        expect(original_task.deadline_date.to_s).to eq(original_attributes['deadline_date'].to_s)
      end
    end

    # ========================================
    # エッジケース（9〜13）
    # ========================================
    context 'explanationがnilの場合' do
      it 'explanationがnilでもエラーにならず、nilのまま引き継がれる' do
        task_without_explanation = Task.create!(
          name: '説明なしタスク',
          genre: genre,
          explanation: nil,
          priority: :low
        )

        service = Tasks::DuplicateService.new(task_without_explanation.id)
        service.call

        expect(service.duplicated_task.explanation).to be_nil
        expect(service.success?).to be true
      end
    end

    context 'deadline_dateが既にnilの場合' do
      it '元からnilでも問題なく複製される' do
        task_without_deadline = Task.create!(
          name: '期限なしタスク',
          genre: genre,
          deadline_date: nil,
          priority: :medium
        )

        service = Tasks::DuplicateService.new(task_without_deadline.id)
        service.call

        expect(service.duplicated_task.deadline_date).to be_nil
        expect(service.success?).to be true
      end
    end

    context 'nameが長い場合' do
      it 'nameが長くても「(コピー)」を追加してエラーにならない' do
        long_name = 'あ' * 100
        task_with_long_name = Task.create!(
          name: long_name,
          genre: genre,
          priority: :high
        )

        service = Tasks::DuplicateService.new(task_with_long_name.id)
        service.call

        expect(service.duplicated_task.name).to eq("#{long_name}(コピー)")
        expect(service.success?).to be true
      end
    end

    context '各priority値での複製' do
      it 'priorityがlowのタスクを複製できる' do
        task_low = Task.create!(name: '低優先度', genre: genre, priority: :low)
        service = Tasks::DuplicateService.new(task_low.id)
        service.call
        expect(service.duplicated_task.priority).to eq('low')
      end

      it 'priorityがmediumのタスクを複製できる' do
        task_medium = Task.create!(name: '中優先度', genre: genre, priority: :medium)
        service = Tasks::DuplicateService.new(task_medium.id)
        service.call
        expect(service.duplicated_task.priority).to eq('medium')
      end

      it 'priorityがhighのタスクを複製できる' do
        task_high = Task.create!(name: '高優先度', genre: genre, priority: :high)
        service = Tasks::DuplicateService.new(task_high.id)
        service.call
        expect(service.duplicated_task.priority).to eq('high')
      end
    end

    context '複製を複数回実行した場合' do
      it '「(コピー)」が連続で追加される' do
        original = Task.create!(name: 'タスクA', genre: genre, priority: :medium)

        # 1回目の複製
        service1 = Tasks::DuplicateService.new(original.id)
        service1.call
        expect(service1.duplicated_task.name).to eq('タスクA(コピー)')

        # 2回目の複製（1回目の複製をさらに複製）
        service2 = Tasks::DuplicateService.new(service1.duplicated_task.id)
        service2.call
        expect(service2.duplicated_task.name).to eq('タスクA(コピー)(コピー)')

        # 3回目の複製
        service3 = Tasks::DuplicateService.new(service2.duplicated_task.id)
        service3.call
        expect(service3.duplicated_task.name).to eq('タスクA(コピー)(コピー)(コピー)')
      end
    end

    # ========================================
    # 異常系
    # ========================================
    context '存在しないタスクIDを指定した場合' do
      it 'falseを返す' do
        service = Tasks::DuplicateService.new(99999)
        expect(service.call).to be false
      end

      it 'success?がfalseを返す' do
        service = Tasks::DuplicateService.new(99999)
        service.call
        expect(service.success?).to be false
      end

      it 'duplicated_taskがnilを返す' do
        service = Tasks::DuplicateService.new(99999)
        service.call
        expect(service.duplicated_task).to be_nil
      end
    end

    context 'nilを指定した場合' do
      it 'falseを返す' do
        service = Tasks::DuplicateService.new(nil)
        expect(service.call).to be false
      end
    end
  end
end
