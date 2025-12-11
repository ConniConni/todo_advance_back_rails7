require 'rails_helper'

RSpec.describe Tasks::StatsService do
  let(:genre) { Genre.create!(name: 'テストジャンル') }

  describe '#call' do
    context 'タスクが存在する場合' do
      before do
        # status: 0 (未着手など) - 2件
        Task.create!(name: 'タスク1', genre: genre, status: 0, priority: :low)
        Task.create!(name: 'タスク2', genre: genre, status: 0, priority: :medium)

        # status: 1 - 1件
        Task.create!(name: 'タスク3', genre: genre, status: 1, priority: :high)

        # status: 3 - 1件
        Task.create!(name: 'タスク4', genre: genre, status: 3, priority: :low)

        # status: 5 (完了) - 2件
        Task.create!(name: 'タスク5', genre: genre, status: 5, priority: :medium)
        Task.create!(name: 'タスク6', genre: genre, status: 5, priority: :high)
      end

      it '全タスク数を正しく計算できること' do
        service = Tasks::StatsService.new
        service.call

        expect(service.result[:total_count]).to eq(6)
      end

      it 'ステータス別タスク数を正しく集計できること' do
        service = Tasks::StatsService.new
        service.call

        expect(service.result[:status_counts][0]).to eq(2)
        expect(service.result[:status_counts][1]).to eq(1)
        expect(service.result[:status_counts][3]).to eq(1)
        expect(service.result[:status_counts][5]).to eq(2)
      end

      it '完了率を正しく計算できること' do
        service = Tasks::StatsService.new
        service.call

        # 6件中2件が完了 -> 33.33...%
        expect(service.result[:completion_rate]).to be_within(0.01).of(33.33)
      end
    end

    context 'タスクが0件の場合' do
      it '全タスク数が0であること' do
        service = Tasks::StatsService.new
        service.call

        expect(service.result[:total_count]).to eq(0)
      end

      it 'ステータス別タスク数が空のハッシュであること' do
        service = Tasks::StatsService.new
        service.call

        expect(service.result[:status_counts]).to eq({})
      end

      it '完了率が0.0であること' do
        service = Tasks::StatsService.new
        service.call

        expect(service.result[:completion_rate]).to eq(0.0)
      end
    end

    context '全てのタスクが完了している場合' do
      before do
        Task.create!(name: 'タスク1', genre: genre, status: 5, priority: :low)
        Task.create!(name: 'タスク2', genre: genre, status: 5, priority: :medium)
        Task.create!(name: 'タスク3', genre: genre, status: 5, priority: :high)
      end

      it '完了率が100.0であること' do
        service = Tasks::StatsService.new
        service.call

        expect(service.result[:completion_rate]).to eq(100.0)
      end
    end

    context '完了タスクが0件の場合' do
      before do
        Task.create!(name: 'タスク1', genre: genre, status: 0, priority: :low)
        Task.create!(name: 'タスク2', genre: genre, status: 1, priority: :medium)
      end

      it '完了率が0.0であること' do
        service = Tasks::StatsService.new
        service.call

        expect(service.result[:completion_rate]).to eq(0.0)
      end
    end

    context '様々なステータスが混在する場合' do
      before do
        [0, 1, 2, 3, 4, 5].each do |status_value|
          Task.create!(
            name: "ステータス#{status_value}のタスク",
            genre: genre,
            status: status_value,
            priority: :medium
          )
        end
      end

      it '全てのステータスが正しく集計されること' do
        service = Tasks::StatsService.new
        service.call

        expect(service.result[:total_count]).to eq(6)
        expect(service.result[:status_counts][0]).to eq(1)
        expect(service.result[:status_counts][1]).to eq(1)
        expect(service.result[:status_counts][2]).to eq(1)
        expect(service.result[:status_counts][3]).to eq(1)
        expect(service.result[:status_counts][4]).to eq(1)
        expect(service.result[:status_counts][5]).to eq(1)
      end

      it '完了率が正しく計算されること' do
        service = Tasks::StatsService.new
        service.call

        # 6件中1件が完了 -> 16.66...%
        expect(service.result[:completion_rate]).to be_within(0.01).of(16.67)
      end
    end
  end
end
