require 'rails_helper'

RSpec.describe Tasks::ReportService do
  let(:genre) { Genre.create!(name: 'テストジャンル') }

  describe '#call' do
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

      it '全タスク数を正しく計算できること' do
        service = Tasks::ReportService.new
        service.call

        expect(service.result[:total_count]).to eq(5)
      end

      it 'ステータス別タスク数を正しく集計できること' do
        service = Tasks::ReportService.new
        service.call

        expect(service.result[:count_by_status][:not_started]).to eq(2)
        expect(service.result[:count_by_status][:in_progress]).to eq(1)
        expect(service.result[:count_by_status][:completed]).to eq(2)
      end

      it '完了率を小数点以下1桁で正しく計算できること' do
        service = Tasks::ReportService.new
        service.call

        # 5件中2件が完了 -> 40.0%
        expect(service.result[:completion_rate]).to eq(40.0)
      end
    end

    context 'タスクが0件の場合' do
      it '全タスク数が0であること' do
        service = Tasks::ReportService.new
        service.call

        expect(service.result[:total_count]).to eq(0)
      end

      it 'ステータス別タスク数がすべて0であること' do
        service = Tasks::ReportService.new
        service.call

        expect(service.result[:count_by_status][:not_started]).to eq(0)
        expect(service.result[:count_by_status][:in_progress]).to eq(0)
        expect(service.result[:count_by_status][:completed]).to eq(0)
      end

      it '完了率が0.0であること' do
        service = Tasks::ReportService.new
        service.call

        expect(service.result[:completion_rate]).to eq(0.0)
      end
    end

    context '全てのタスクが完了している場合' do
      before do
        Task.create!(name: 'タスク1', genre: genre, status: :completed, priority: :low)
        Task.create!(name: 'タスク2', genre: genre, status: :completed, priority: :medium)
        Task.create!(name: 'タスク3', genre: genre, status: :completed, priority: :high)
      end

      it '完了率が100.0であること' do
        service = Tasks::ReportService.new
        service.call

        expect(service.result[:completion_rate]).to eq(100.0)
      end
    end

    context '完了タスクが0件の場合' do
      before do
        Task.create!(name: 'タスク1', genre: genre, status: :not_started, priority: :low)
        Task.create!(name: 'タスク2', genre: genre, status: :in_progress, priority: :medium)
      end

      it '完了率が0.0であること' do
        service = Tasks::ReportService.new
        service.call

        expect(service.result[:completion_rate]).to eq(0.0)
      end
    end

    context '完了率が小数点以下1桁で切り捨てされる場合' do
      before do
        # 3件中1件完了 -> 33.333...% -> 33.3%
        Task.create!(name: 'タスク1', genre: genre, status: :not_started, priority: :low)
        Task.create!(name: 'タスク2', genre: genre, status: :not_started, priority: :medium)
        Task.create!(name: 'タスク3', genre: genre, status: :completed, priority: :high)
      end

      it '完了率が小数点以下1桁で計算されること' do
        service = Tasks::ReportService.new
        service.call

        expect(service.result[:completion_rate]).to eq(33.3)
      end
    end
  end
end
