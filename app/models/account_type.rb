class AccountType < ActiveRecord::Base
  
  def self.populate
    self.truncate
    arr = ["Service","Program","Personality"] 
    arr.each do |r|
      self.create :name => r
    end
  end
  
end
