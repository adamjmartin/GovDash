class AppToken < ActiveRecord::Base

  self.table_name = "app_tokens"

  def get_access_token times=1
    return nil if times > 3
    if self.page_access_token && 
       self.updated_at > 55.minutes.ago
      self.page_access_token
    else
      callback_url = canvas_url
      @oauth = Koala::Facebook::OAuth.new(client_id, client_secret, callback_url)
      begin
        access_token = @oauth.get_app_access_token
        self.update_attributes page_access_token: access_token,
            updated_at: Time.zone.now
        access_token
      rescue Exception=>ex
        times = times + 1
        logger.error ex.message
        logger.info "  retry #{times} times in 5 seconds"
        sleep 5
        access_token = get_access_token times
      end
    end 
  end
  
  def exchange_page_access_token(access_token)
    if !access_token
      raise "  AppToken#exchange_page_access_token access_token is null"
    end
    obj=FacebookAccount.where("is_active=1").last.send "object_name"
    page_token = graph_api(access_token).graph_call("v2.2/#{obj}?fields=access_token&access_token=#{access_token}")
    if page_token['access_token']
      self.page_access_token = page_token['access_token']
      self.save!
    else
      logger.info "  #{self.class.name} no page_access_token"
    end
  end
    
end
=begin 

  def token?
    !!page_access_token
  end
  
  def debug_token
    if token?
      'never'
    else
      'N/A'
    end
  end
=end