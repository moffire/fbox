require 'rails_helper'
require 'mock_redis'

describe 'Fun Box API', type: :request do
  describe 'GET /visited_domains' do

    before do |testcase|
      if testcase.metadata[:set_data]
        post '/visited_links', params: { links: %w[https://ya.ru https://ya.ru?q=123 funbox.ru http://google.com/] }
      end
    end

    it 'returns error with unknown params' do
      get '/visited_domains?min=1&max=2'
      expect(response.status).to eq 400
      status_message = JSON.parse(response.body)
      expect(status_message['status']).to eq "Params 'from' or 'to' are not given"
    end

    it 'returns error with empty params' do

      # param 'to' is empty
      get '/visited_domains?from=1&to='
      expect(response.status).to eq 400
      status_message = JSON.parse(response.body)
      expect(status_message['status']).to eq 'One or more params have a zero length value'

      # param 'from' is empty
      get '/visited_domains?from=&to=2'
      status_message = JSON.parse(response.body)
      expect(status_message['status']).to eq 'One or more params have a zero length value'
    end

    it "returns error if param 'from' is greater than 'to'" do
      get '/visited_domains?from=10&to=2'
      expect(response.status).to eq 400
      status_message = JSON.parse(response.body)
      expect(status_message['status']).to eq "Param value 'from' should be less than 'to'"
    end

    it "returns error if params are not numeric" do
      get '/visited_domains?from=abc&to=def'
      expect(response.status).to eq 400
      status_message = JSON.parse(response.body)
      expect(status_message['status']).to eq "Invalid params value"
    end

    it 'returns unique domains', :set_data do
      get "/visited_domains?from=#{Time.now.to_i}&to=#{Time.now.to_i}"
      expect(JSON.parse(response.body)['domains'].length).to eq 3
      REDIS.flushdb
    end

    it "doesn't return any domain", :set_data do
      # set time in a past where's no objects
      get "/visited_domains?from=#{Time.now.to_i - 200}&to=#{Time.now.to_i - 100}"
      expect(JSON.parse(response.body)['domains'].length).to eq 0

      # set time in a future where's no objects
      get "/visited_domains?from=#{Time.now.to_i + 100}&to=#{Time.now.to_i + 200}"
      expect(JSON.parse(response.body)['domains'].length).to eq 0

      REDIS.flushdb
    end

  end

  describe 'POST /visited_links' do

    it "returns error if params are empty or not given" do

      # param 'links' is empty
      post '/visited_links', params: { links: {} }

      expect(response.status).to eq 400
      status_message = JSON.parse(response.body)
      expect(status_message['status']).to eq "Empty request params"

      # param 'links' is not given
      post '/visited_links', params: {}

      expect(response.status).to eq 400
      status_message = JSON.parse(response.body)
      expect(status_message['status']).to eq "Empty request params"

    end
  end
end

