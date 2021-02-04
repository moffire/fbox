Rails.application.routes.draw do
  post '/visited_links', to: 'fb_api#visited_links'
  get '/visited_domains', to: 'fb_api#visited_domains'
end
