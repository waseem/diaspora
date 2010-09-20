#   Copyright (c) 2010, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3.  See
#   the COPYRIGHT file.


class Writ
  require 'lib/diaspora/webhooks'
  include MongoMapper::Document
  include Diaspora::Webhooks
  include ROXML

  xml_reader :_id
  xml_reader :sender, :as => Person
  xml_reader :destination_url
  xml_reader :callback_url
  xml_reader :exported_key, :cdata => true

  key :destination_url, String
  key :callback_url,    String
  key :exported_key,    String

  belongs_to :sender, :class_name => 'Person'

  validates_presence_of :destination_url, :callback_url

  scope :for_user,  lambda{ |user| where(:destination_url    => user.receive_url) }
  scope :from_user, lambda{ |user| where(:destination_url.ne => user.receive_url) }

  def self.instantiate(options = {})
    sender = options[:from]
    writ = new(:destination_url => options[:to],
             :callback_url    => sender.receive_url,
             :sender          => sender,
             :exported_key    => sender.exported_key)
    writ.clean_link
    writ
  end

  def clean_link
    if self.destination_url
      self.destination_url = 'http://' + self.destination_url unless self.destination_url.match('https?://')
      self.destination_url = self.destination_url + '/' if self.destination_url[-1,1] != '/'
    end
  end
end
