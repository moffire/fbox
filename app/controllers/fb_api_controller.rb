require 'redis'

class FbApiController < ApplicationController

  $redis = Redis.new

  def visited_links

    timestamp = Time.now.to_i

    links = params[:links]

    if links.nil?
      return render json: { 'status': 'Unknown request params' }, status: 400
    end

    # add a random float number after each link to prevent rewriting
    # and store them into redis with timestamp as score value
    links.each{ |link| $redis.zadd('links', timestamp, link + " [#{ rand.to_s }]") unless link.empty? }

    render json: { 'status': 'OK' }, status: 200

  end

  def visited_domains
    date_from, date_to = params['from'], params['to']

    if date_from.nil? || date_to.nil?
      return render json: { 'status': 'Unknown request params' }, status: 400
    end

    if date_from.empty? || date_to.empty?
      return render json: { 'status': 'One or more params has a zero length value' }, status: 400
    end

    if date_from > date_to
      return render json: { 'status': "Param 'from' should be less than 'to'" }, status: 400
    end

    begin
      visited_links = $redis.zrangebyscore('links', date_from, date_to)
    rescue Redis::CommandError
      return render json: { 'status': 'Invalid params values' }, status: 400
    end

    domains = Set.new
    visited_links.each do |link|
      unless link.start_with?('http')
        link = 'http://' + link
      end
      # remove uniq float part
      cleared_link = link.split(' ').first
      begin
        domains << URI.parse(cleared_link).host unless nil
      rescue URI::InvalidURIError
        # Ignored
      end
    end

    render json: {'domains': domains, 'status': 'OK'}, status: 200

  end
end
