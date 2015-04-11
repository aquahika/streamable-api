require 'faraday'
require 'json'

require 'pp'

module Streamable


  class Streamable

    def initialize args={}

      throw ArgumentError "User ID not specified" if args[:user].nil?
      throw ArgumentError "User Password not specified" if args[:password].nil?

      @user     =  args[:user]
      @password =  args[:password]

      @streamable = Faraday.new(:url => 'https://api.streamable.com') do |builder|
        builder.request :multipart   # マルチパートでデータを送信
        builder.adapter :net_http
        builder.basic_auth @user, @password
      end

    end

    def upload video_path
      params= {:file => Faraday::UploadIO.new(video_path, 'video/mp4')}
      res =  @streamable.post '/upload' ,params
      pp res.body
      body = JSON.parse(res.body,symbolize_names: true)[0]
      pp body
      return body[:shortcode]
    end

    def status shortcode
      res = @streamable.get '/videos/'+shortcode
      return Video.new(shortcode,JSON.parse(res.body,symbolize_names: true))
    end

  end

  class Video
    class VideoStatus; end
    class Ready < VideoStatus;   end
    class Processing < VideoStatus; end
    class Uploading < VideoStatus; end
    class Error < VideoStatus; end

    def initialize shortcode,args={}
      raise "shortcode must be specified" if shortcode.nil?
      raise "shortcode must be String" unless shortcode.instance_of?(String)
      @shortcode = shortcode
      @status = args[:status]
      @message= args[:message]
      @url_root = args[:url_root]
      @formats = args[:formats]
    end

    def mp4_url
      return 'https:'+@url_root+'.mp4'
    end

    def status
     case @status
        when 2 then return Ready.new
        when 1 then return Processing.new 
        when 0 then return Uploading.new
        when 3 then return Error.new
      end
    end
  end
end


hoge = Streamable::Streamable.new(:user => "loby" , :password => "OFAlR57pwtqru_wh15ctEw")
pp shortcode = hoge.upload("video.mp4")
pp video = hoge.status(shortcode)
p video.mp4_url

loop  do
video = hoge.status(shortcode)
p video.status
sleep 2
end
