require 'rails_helper'

RSpec.describe Tasks::CreateService do
  let(:genre) { Genre.create!(name: 'テストジャンル') }

  describe '#call' do
    context '有効なパラメータの場合' do
      let(:params) do
        {
          name: 'テストタスク',
          explanation: 'テストの説明',
          status: 'pending',
          priority: '1',
          genreId: genre.id,
          deadlineDate: '2025-12-31'
        }
      end

      it 'Taskが作成される' do
        expect {
          Tasks::CreateService.new(params).call
        }.to change(Task, :count).by(1)
      end

      it 'priorityが整数に変換される' do
        service = Tasks::CreateService.new(params)
        service.call
        expect(service.task.priority).to eq('medium')
      end

      it 'genre_idが正しく設定される' do
        service = Tasks::CreateService.new(params)
        service.call
        expect(service.task.genre_id).to eq(genre.id)
      end

      it 'deadline_dateが正しく設定される' do
        service = Tasks::CreateService.new(params)
        service.call
        expect(service.task.deadline_date.to_s).to eq('2025-12-31')
      end

      it 'trueを返す' do
        service = Tasks::CreateService.new(params)
        expect(service.call).to be true
      end

      it 'success?がtrueを返す' do
        service = Tasks::CreateService.new(params)
        service.call
        expect(service.success?).to be true
      end
    end

    context 'priorityが文字列の"0"の場合' do
      let(:params) do
        {
          name: '低優先度タスク',
          genreId: genre.id,
          priority: '0'
        }
      end

      it 'priorityがlowに設定される' do
        service = Tasks::CreateService.new(params)
        service.call
        expect(service.task.priority).to eq('low')
      end
    end

    context 'priorityが文字列の"2"の場合' do
      let(:params) do
        {
          name: '高優先度タスク',
          genreId: genre.id,
          priority: '2'
        }
      end

      it 'priorityがhighに設定される' do
        service = Tasks::CreateService.new(params)
        service.call
        expect(service.task.priority).to eq('high')
      end
    end

    context 'priorityパラメータが存在しない場合' do
      let(:params) do
        {
          name: 'デフォルト優先度タスク',
          genreId: genre.id
        }
      end

      it 'Taskが作成される' do
        expect {
          Tasks::CreateService.new(params).call
        }.to change(Task, :count).by(1)
      end

      it 'priorityにはデフォルト値が設定される' do
        service = Tasks::CreateService.new(params)
        service.call
        expect(service.task.priority).not_to be_nil
      end
    end

    context 'nameが空の場合' do
      let(:params) { { name: nil, genreId: genre.id } }

      it 'Taskは作成される（バリデーションがないため）' do
        expect {
          Tasks::CreateService.new(params).call
        }.to change(Task, :count).by(1)
      end

      it 'trueを返す' do
        service = Tasks::CreateService.new(params)
        expect(service.call).to be true
      end
    end

    context 'genreIdがない場合' do
      let(:params) do
        {
          name: 'タスク',
          priority: '1'
        }
      end

      it 'Taskが作成されない' do
        expect {
          Tasks::CreateService.new(params).call
        }.not_to change(Task, :count)
      end

      it 'falseを返す' do
        service = Tasks::CreateService.new(params)
        expect(service.call).to be false
      end
    end

    context 'オプションパラメータの処理' do
      let(:params) do
        {
          name: 'シンプルなタスク',
          genreId: genre.id
        }
      end

      it 'explanationとstatusとdeadline_dateがなくてもTaskが作成される' do
        expect {
          Tasks::CreateService.new(params).call
        }.to change(Task, :count).by(1)
      end
    end
  end
end
