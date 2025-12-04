require 'rails_helper'

RSpec.describe Task, type: :model do
  let(:genre) { Genre.create!(name: 'テストジャンル') }

  describe '優先度（priority）' do
    context '優先度が指定されている場合' do
      it '優先度が「低」であること' do
        task = Task.create!(
          name: 'テストタスク',
          genre: genre,
          priority: :low
        )
        expect(task.priority).to eq('low')
        expect(task.low?).to be true
      end

      it '優先度が「中」であること' do
        task = Task.create!(
          name: 'テストタスク',
          genre: genre,
          priority: :medium
        )
        expect(task.priority).to eq('medium')
        expect(task.medium?).to be true
      end

      it '優先度が「高」であること' do
        task = Task.create!(
          name: 'テストタスク',
          genre: genre,
          priority: :high
        )
        expect(task.priority).to eq('high')
        expect(task.high?).to be true
      end
    end

    context '優先度が指定されていない場合' do
      it '新規タスク作成時に、優先度のデフォルト値が「中」であること' do
        task = Task.create!(
          name: 'テストタスク',
          genre: genre
        )
        expect(task.priority).to eq('medium')
        expect(task.medium?).to be true
      end
    end

    context '無効な優先度が指定された場合' do
      it 'ArgumentErrorが発生すること' do
        expect {
          Task.create!(
            name: 'テストタスク',
            genre: genre,
            priority: :invalid
          )
        }.to raise_error(ArgumentError)
      end
    end
  end
end
