#   Copyright (c) 2010, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3.  See
#   the COPYRIGHT file.



require File.dirname(__FILE__) + '/../spec_helper'

describe Writ do
  before do
    @user = Factory.create(:user)
    @person = Factory.create(:person)
    @aspect = @user.aspect(:name => "dudes")
    @writ = Writ.new(:destination_url => @person.receive_url,
                     :callback_url =>@user.receive_url)
  end
  it "is valid" do
    @writ.should be_valid
  end
  it 'should require a destination url' do
    @writ.destination_url = nil
    @writ.should_not be_valid
  end
  it 'should require a destination url' do
    @writ.callback_url = nil
    @writ.should_not be_valid
  end

  it 'should generate xml for the User as a Person' do
    writ = @user.inscribe @person, :into => @aspect
    xml = writ.to_xml.to_s

    xml.include?(@user.person.diaspora_handle).should be true
    xml.include?(@user.person.url).should be true
    xml.include?(@user.profile.first_name).should be true
    xml.include?(@user.profile.last_name).should be true
  end
end
