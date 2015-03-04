class YtChannel < ActiveRecord::Base
  belongs_to :youtube_account, foreign_key: :account_id
  
  after_save :sync_redshift
   
  def yt_videos
    @yt_videos ||= 
       YtVideo.where("account_id = #{self.account_id}").to_a
  end
  
  def sync_redshift
    attr = self.attributes
    RedshiftYtChannel.create_or_update(attr)
  end
  # bin/delayed_job restart 
  # to clear cache of method create_or_update
  handle_asynchronously :sync_redshift, :run_at => Proc.new { 5.seconds.from_now }
  
  
end
