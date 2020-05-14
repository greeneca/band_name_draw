require 'net/http'
#require 'byebug'

class DrawNameController < ApplicationController
  def index
    unless session[:auth_object]
      @login_required = true
      redirect_url = ENV['REDIRECT_HOST'] + "/get_token"
      @login_link = "https://auth.band.us/oauth2/authorize?response_type=code&client_id=#{ENV['CLIENT_ID']}&redirect_uri=#{CGI.escape(redirect_url)}"
    else
      @login_required = false
      uri = "https://openapi.band.us/v2/bands?access_token=#{session[:auth_object]['access_token']}"
      result = makeRequest(uri)
      if result.code == "200"
        @bands = JSON.parse(result.body)["result_data"]["bands"]
      else
        logger.fatal "Error getting gist of bands"
        logger.fatal result.body
        redirect_to "/error"
      end
    end
  end

  def get_token
    if params['code']
      uri = "https://auth.band.us/oauth2/token?grant_type=authorization_code&code=#{params['code']}"
      result = makeRequest(uri, {'Authorization': "Basic #{ENV['AUTH_HEADER']}"}, true)
      if result.code == "200"
        session[:auth_object] = JSON.parse(result.body)
        redirect_to "/" and return
      end
      logger.fatal "Error getting auth token"
      logger.fatal result.body
    else
      logger.fatal "Missing auth code"
    end
    redirect_to "/error"
  end

  def band
    unless params['band_key']
      logger.fatal "Missing band key"
      redirect_to "/error" and return
    end
    uri = "https://openapi.band.us/v2/band/posts?access_token=#{session[:auth_object]['access_token']}&band_key=#{params["band_key"]}&locale=en_US"
    if params["after"]
      uri += "&after=#{params["after"]}"
    end
    result = makeRequest(uri)
    if result.code == "200"
      result_data = JSON.parse(result.body)["result_data"]
      @posts = result_data["items"]
      if result_data["paging"] and result_data["paging"]["next_params"] and result_data["paging"]["next_params"]["after"]
        @next = result_data["paging"]["next_params"]["after"]
      end
      if result_data["paging"] and result_data["paging"]["previous_params"] and result_data["paging"]["previous_params"]["after"]
        @previous = result_data["paging"]["previous_params"]["after"]
      end
    else
      logger.fatal "Error getting list of posts"
      logger.fatal result.body
      redirect_to "/error"
    end
  end

  def post
    unless params['band_key'] and params['post_key']
      logger.fatal "Missing band key or post key"
      redirect_to "/error" and return
    end
    session['winners'] ||= {}
    if session['winners'][params['post_key']].class == String
      session['winners'][params['post_key']] = [session['winners'][params['post_key']]]
    end
    setCommenters()
    setWinners()
    if @winners.count == 0
      @winners.push @commenters.sample
      session['winners'][params["post_key"]] = @winners
    end
  end

  def post_reroll
    setCommenters()
    setWinners()
    if params['reroll'].to_i
      @winners[params['reroll'].to_i] = (@commenters-@winners).sample
      session['winners'][params["post_key"]] = @winners
    end
    redirect_to "/post?band_key=#{params['band_key']}&post_key=#{params['post_key']}" and return
  end

  def post_add
    setCommenters()
    setWinners()
    @winners.push (@commenters-@winners).sample
    session['winners'][params["post_key"]] = @winners
    redirect_to "/post?band_key=#{params['band_key']}&post_key=#{params['post_key']}" and return
  end

  def post_reset
    session['winners'][params['post_key']] = nil
    redirect_to "/post?band_key=#{params['band_key']}&post_key=#{params['post_key']}" and return
  end

  def post_refresh
    getComments(true)
    redirect_to "/post?band_key=#{params['band_key']}&post_key=#{params['post_key']}" and return
  end

  def logout
    session[:auth_object] = nil
    redirect_to "/"
  end

  def error
  end

  private

  def getComments(force_refresh = false)
    base_uri = "https://openapi.band.us/v2/band/post/comments?access_token=#{session[:auth_object]['access_token']}&band_key=#{params["band_key"]}&post_key=#{params["post_key"]}"
    done = false
    after = nil
    comments = []
    while not done
      if after
        uri = base_uri + "&after=#{after}"
      else
        uri = base_uri
      end
      result = makeRequest(uri, nil, force_refresh)
      if result.code == "200"
        result_data = JSON.parse(result.body)["result_data"]
        comments.concat(result_data["items"])
        if result_data["paging"] and result_data["paging"]["next_params"] and result_data["paging"]["next_params"]["after"]
          after = result_data["paging"]["next_params"]["after"]
        else
          done = true
        end
      else
        done = true
      end
    end
    comments
  end

  def setCommenters
    comments = getComments()
    commenters = comments.inject([]) do |commenters, comment|
      commenters.push(comment["author"]["name"])
      commenters
    end
    commenters.uniq!
    commenters.sort!
    @commenters = commenters
  end

  def setWinners
    @winners = session['winners'][params['post_key']]
    @winners ||= []
  end

  def makeRequest(uri, request_headers=nil, force_refresh=false)
    Rails.cache.fetch(uri, force: force_refresh, expires_in: 1.hour) do
      puts "Requesting: "+uri
      uri = URI.parse(uri)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      req = Net::HTTP::Get.new(uri.request_uri)
      if request_headers
        request_headers.each_pair do |k,v|
          req[k] = v
        end
      end
      http.request(req)
    end
  end
end
