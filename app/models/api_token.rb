# this model is to be replaced by AppToken
=begin
class ApiToken < ActiveRecord::Base
 
  belongs_to :facebook_account, foreign_key: :account_id
  
  def graph_api(access_token=nil)
    access_token = access_token || page_access_token || user_access_token
    @graph_api = Koala::Facebook::API.new(access_token)
  end
  
  def exchange_page_access_token(access_token=nil)
    token = access_token || user_access_token
    begin
      page_token = graph_api(access_token).graph_call("v2.0/#{self.facebook_account.send(:obj_name)}?fields=access_token&access_token=#{token}")
      if page_token['access_token']
        self.update_attribute :page_access_token, page_token['access_token']
      else
        self.update_attribute :user_access_token, access_token if access_token
        logger.info "ApiToken: #{self.canvas_url} : #{self.facebook_account.object_name} : no page_token['access_token']"
      end
    rescue Exception=>error
      logger.error error.message
    end
  end
  
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
end
=end

