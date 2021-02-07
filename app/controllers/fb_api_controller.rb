require 'redis'

class FbApiController < ApplicationController

  def visited_links

    if stored_to_db?(params[:links])
      render json: { 'status': 'OK' }, status: 200
    else
      render json: { 'status': 'Empty request params' }, status: 400
    end
  end


  def visited_domains

    date_from, date_to = params['from'], params['to']

    if date_from.nil? || date_to.nil?
      return render json: { 'status': "Params 'from' or 'to' are not given" }, status: 400
    end

    if date_from.empty? || date_to.empty?
      return render json: { 'status': 'One or more params have a zero length value' }, status: 400
    end

    if date_from.to_i > date_to.to_i
      return render json: { 'status': "Param value 'from' should be less than 'to'" }, status: 400
    end

    begin
      visited_links = REDIS.zrangebyscore('links', date_from, date_to)
    rescue Redis::CommandError
      return render json: { 'status': 'Invalid params value' }, status: 400
    end

    unique_domains = get_unique_domains(visited_links)

    render json: {'domains': unique_domains, 'status': 'OK'}, status: 200

  end

  def stored_to_db?(links)
    if links.nil?
      false
    elsif links.empty?
      false
    else
      timestamp = Time.now.to_i
      # add a random float number after each link to prevent rewriting
      # and store them into redis with timestamp as a score value
      links.each { |link| REDIS.zadd('links', timestamp, link + " [#{ rand.to_s }]") }
      true
    end
  end


  def get_unique_domains(links)
    domains = Set.new
    links.each do |link|
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
    domains
  end
end
