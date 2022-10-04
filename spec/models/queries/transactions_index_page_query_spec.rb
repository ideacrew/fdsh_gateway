# frozen_string_literal: true

require 'rails_helper'

# Spec for Queries::TransactionsIndexPageQuery
RSpec.describe Queries::TransactionsIndexPageQuery, db_clean: :after_each do
  before :all do
    DatabaseCleaner.clean
  end

  let(:transactions) { FactoryBot.create_list(:transaction, 30, :with_activity) }
  let(:query) { Queries::TransactionsIndexPageQuery.new }

  before do
    @default_per_page = Kaminari.config.default_per_page
  end

  it 'should require the page number argument' do
    expect { query.call }.to raise_error ArgumentError, 'missing keyword: :page'
  end

  it 'should return a Mongo::Collection::View::Aggregation object' do
    expect(query.call(page: 1)).to be_a Mongo::Collection::View::Aggregation
  end

  it "should return at most #{@default_per_page} results per query" do
    transactions
    result = query.call(page: 1)
    expect(result.count).to eq @default_per_page
  end

  it 'should sort results newest to oldest based on activity updated_at field' do
    transactions
    result = query.call(page: 1).to_a
    result.each_with_index do |record, index|
      expect(record['activities']['updated_at']).to be >= result[index + 1]['activities']['updated_at'] unless index == result.count - 1
    end
  end

  context 'with search id' do
    it 'should return only results matching the search critera' do
      id = transactions.last.correlation_id
      result = query.call(id, page: 1)
      expect(result.count).to eq 1
    end

    it 'should match id strings with special regex characters' do
      special_id = 'id_.1+2*3?4^5$6(7)8[9]a{b}c|d\e'
      transactions.last.update(correlation_id: special_id)
      result = query.call(special_id, page: 1)
      expect(result.count).to eq 1
    end
  end
end