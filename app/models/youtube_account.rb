class YoutubeAccount < Account
  has_many :yt_channels, foreign_key: :account_id
  has_many :yt_videos, foreign_key: :account_id
  
  # run this only once
  def self.initial_load
    YoutubeAccount.where("is_active is not null").to_a.each do | yt |
      yt.initial_load
    end
  end
  
  def self.retrieve
    YoutubeAccount.where("is_active is not null").to_a.each do | yt |
      yt.retrieve
    end
  end

  def initial_load
    process_channel
    @bulk_insert = []
    started = Time.now
    i = channel.video_count
    channel.videos.each do |v|
      i -= 1
      begin
        # video = Yt::Video.new id: v.id
        hs = construct_hash(v)
        # v.update_attributes hs
        @bulk_insert << hs
        if @bulk_insert.size > 500
          say "  initial_load: upload data for #{@bulk_insert.size} videos"
          YtVideo.import! @bulk_insert
          @bulk_insert = []
        end
      rescue Exception=>ex
        logger.error "  #{self.class.name}#initial_load #{ex.message}"
      end 
      if ( (i % 20) == 0 || i > 0 )
        say "  #{i} videos remain", Logger::Severity::DEBUG
      end
    end
    say "  initial_load: upload data for #{@bulk_insert.size} videos"
    YtVideo.import! @bulk_insert
    
    summarize
    
    ended = Time.now
    log_duration started, ended
    @bulk_insert = []
  end
  # handle_asynchronously :initial_load, :run_at => Proc.new {10.seconds.from_now }
  
  def retrieve
    # to prevent attack from the youtube.yml, such as
    # YoutubeConf[:since_date] = "Account.destroy_all"
    # 
    arr = YoutubeConf[:since_date].split('.')
    n = arr[0].to_i
    if n == 0
      raise "  YoutubeAccount#retrieve incorrect YoutubeConf[:since_date] format"
    end
    unit = arr[1].match(/days|months/)
    unless unit
      raise "  YoutubeAccount#retrieve incorrect YoutubeConf[:since_date] format"
    end
    sincedate = eval("#{n}.#{unit}.#{arr[2]}")
    
    @bulk_insert = []
    say "Started #{self.class.name}#retrieve"
    
    process_channel
   
    @bulk_insert = []
    started = Time.now
    changed_videos = []
    channel.videos.each do |v|
      if v.published_at.to_i > sincedate.to_i
        begin
          hs = construct_hash(v)
          video = self.yt_videos.find_or_create_by video_id: v.id
          video.update_attributes hs
=begin
          @bulk_insert << hs
          if @bulk_insert.size > 500
            say "Process #{v.published_at.to_s(:db)}"
            bulk_import
            @bulk_insert = []
          end
=end
        rescue Exception=>ex
          logger.error "  #{self.class.name}#initial_load #{ex.message}"
        end
      else
        logger.debug "  Skip #{v.published_at.to_s(:db)}"
        break 
      end
    end

    summarize sincedate
    
    ended = Time.now
    log_duration started, ended
    @bulk_insert = []
  end
  # handle_asynchronously :retrieve, :run_at => Proc.new {10.seconds.from_now }
  
  def summarize init_date=nil
    videos = self.yt_videos
    
    if !init_date
      init_date = videos.select("min(published_at) AS published_at").
        to_a.first.published_at
    end
    @channel_insert = []
    while init_date < Time.zone.now
      s_date = init_date.beginning_of_day
      e_date = init_date.end_of_day
      my_videos = videos.where("published_at BETWEEN '#{s_date}' AND '#{e_date}'").to_a
      unless my_videos.empty?      
        summary_for_day init_date, my_videos
      end
      init_date += 1.day 
    end
    
    unless @channel_insert.empty?
      YtChannel.import! @channel_insert
    end
    @channel_insert = []
  end
  
  def channel
    @channel ||=
       Yt::Channel.new url: "youtube.com/#{object_name}"
  end
  
  protected
  
  def construct_hash video
    hs = {:account_id => self.id,
          :video_id => video.id,
          :published_at => video.published_at.to_s(:db),
          :likes => video.like_count - video.dislike_count,
          :comments => video.comment_count,
          :views => video.view_count,
          :favorites => video.favorite_count}
  end
  
  def bulk_import
    unless @bulk_insert.empty?
      begin
        YtVideo.import! @bulk_insert
      rescue Exception=>ex
        logger.error " #{self.class.name}#bulk_import #{ex.message}"
      end
    end
  end
  
  def process_channel
    # create daily yt_channel based on created_at
    published = Time.now.middle_of_day.to_s(:db)
    yt_ch = self.yt_channels.find_or_create_by channel_id: channel.id, published_at: published
    yt_ch.account_id=self.id
    yt_ch.views = channel.view_count
    yt_ch.comments = channel.comment_count
    yt_ch.videos = channel.video_count
    yt_ch.subscribers = channel.subscriber_count
    # channel.published_at
    yt_ch.save
  end
    
  def log_duration started, ended
    total_seconds = (ended - started)
    seconds = total_seconds % 60
    minutes = (total_seconds / 60) % 60
    hours = total_seconds / (60 * 60)
    duration = format("%02d:%02d:%02d", hours, minutes, seconds)
    say " #{ended.to_s(:db)} Ended #{self.class.name}"
    say " Duration: #{duration}"
  end
  #
  # recursively get total_likes etc. for each day in yt_channels
  #  
  def summary_for_day init_date, videos
    likes = 0
    comments = 0
    favorites = 0
    views = 0
    videos.each do | v |
      likes += v.likes
      comments += v.comments
      favorites += v.favorites
      views += v.views
    end
    totals = {:published_at => init_date.middle_of_day,
              :account_id => self.id,
              :channel_id=>self.channel.id,
              :video_comments => comments,
              :video_favorites => favorites,
              :video_likes => likes,
              :video_views => views}

    ch = self.yt_channels.find_by published_at: init_date.middle_of_day
    if ch
      if ch.video_comments != totals[:total_comments] ||
         ch.video_favorites != totals[:total_favorites] ||
         ch.video_likes != totals[:total_likes] ||
         ch.video_views != totals[:total_views]
       
         ch.video_attributes totals
      end
    else
      # new record
      @channel_insert << totals
    end
  end
  
end
=begin
  def save_video vid
    begin
      video = Yt::Video.new id: vid
      v = YtVideo.find_or_create_by video_id: video.id
      hs = {:account_id => self.id,
            :channel_id => channel.id,
            :video_id => video.id,
            :published_at => "#{video.published_at.to_s(:db)}",
            :likes => video.like_count - video.dislike_count,
            :comments => video.comment_count,
            :favorites => video.favorite_count}
      # @bulk_insert << hs
      v.update_attributes hs
      video.published_at
    rescue Exception=>ex
      Rails.logger.error "  #{self.class.name}#save_video #{ex.message}"
      nil
    end 
  end
  
  def init
    @bulk_insert = []
    @next_page_token = nil
    @last_published_at = nil
  end

  def process_results
    results  = fetch
    @next_page_token = results['nextPageToken']
    if @next_page_token
      @next_page_token = "&pageToken=#{@next_page_token}"
    end
    unless results.empty?
      results['items'].each do |item|
        vid = item['id']['videoId']
        @last_published_at = save_video vid
      end  
    end
    if @last_published_at && @last_published_at > eval(conf.since_date)
      process_results
    else
      @last_published_at
    end
  end
  
  def path
    endpoint="https://www.googleapis.com/youtube/v3/search"
    api_key = YoutubeConf[:api_key]
    "#{endpoint}?channelId=#{channel.id}&key=#{api_key}&maxResults=#{max_results}&order=date&part=snippet&type=video"
  end

  def fetch
    url = self.path
    if @next_page_token
      url = url + @next_page_token
    end
    uri = URI.parse(url)
    req = Net::HTTP::Get.new(uri)
    http = Net::HTTP.new(uri.hostname, uri.port)
    http.use_ssl = true if uri.scheme == 'https'
    http.read_timeout = YoutubeConf[:read_timeout] || 60
    http.open_timeout = YoutubeConf[:open_timeout] || 60
    response=nil
    http.start do |h|
      response = h.request(req)
      case response
        when (Net::HTTPOK || Net::HTTPSuccess)
        else
          response.error!
      end
    end
    if response
      hsh = JSON.parse response.body
    else
      {}
    end
    
  end
  
  def max_results
    @max_results ||= YoutubeConf[:max_results] || 50
  end
=end

