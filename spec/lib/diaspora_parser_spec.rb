#   Copyright (c) 2010, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3.  See
#   the COPYRIGHT file.

require 'spec_helper'

describe Diaspora::Parser do
  before do
    @user = Factory.create(:user, :email => "bob@aol.com")
    @aspect = @user.aspect(:name => 'spies')

    @user3 = Factory.create :user
    @person = @user3.person
    @user2 = Factory.create(:user)
  end

  describe "parsing compliant XML object" do
    before do
      @xml = Factory.build(:status_message).to_diaspora_xml
    end

     it 'should be able to correctly handle comments with person in db' do
      person = Factory.create(:person, :diaspora_handle => "test@testing.com")
      post = Factory.create(:status_message, :person => @user.person)
      comment = Factory.build(:comment, :post => post, :person => person, :text => "Freedom!")
      xml = comment.to_diaspora_xml

      comment = Diaspora::Parser.from_xml(xml)
      comment.text.should == "Freedom!"
      comment.person.should == person
      comment.post.should == post
    end

    it 'should be able to correctly handle person on a comment with person not in db' do
      commenter = Factory.create(:user)
      commenter_aspect = commenter.aspect :name => "bruisers"
      friend_users(@user, @aspect, commenter, commenter_aspect)
      post = @user.post :status_message, :message => "hello", :to => @aspect.id
      comment = commenter.comment "Fool!", :on => post

      xml = comment.to_diaspora_xml
      commenter.delete
      commenter.person.delete

      parsed_person = Diaspora::Parser::parse_or_find_person_from_xml(xml)
      parsed_person.save.should be true
      parsed_person.diaspora_handle.should == commenter.person.diaspora_handle
      parsed_person.profile.should_not be_nil
    end

    it 'should marshal retractions' do
      person = Factory.create(:person)
      message = Factory.create(:status_message, :person => person)
      retraction = Retraction.for(message)
      xml = retraction.to_diaspora_xml

      StatusMessage.count.should == 1
      @user.receive xml
      StatusMessage.count.should == 0
    end

    it "should create a new person upon getting a writ" do
      person_count = Person.all.count
      writ = Writ.instantiate :to => @user.person, :from => @person

      original_person_id = @person.id
      xml = writ.to_diaspora_xml

      @user3.destroy
      @person.destroy
      Person.all.count.should == person_count -1
      @user.receive xml
      Person.all.count.should == person_count

      Person.first(:_id => original_person_id).serialized_public_key.include?("PUBLIC").should be true
      url = "http://" + writ.callback_url.split("/")[2] + "/"
      Person.where(:url => url).first.id.should == original_person_id
    end

    it "should not create a new person if the person is already here" do
      person_count = Person.all.count
      writ = Writ.instantiate :to => @user.person, :from => @user2.person

      original_person_id = @user2.person.id
      xml = writ.to_diaspora_xml

      Person.all.count.should be person_count
      @user.receive xml
      Person.all.count.should be person_count

      @user2.reload
      @user2.person.reload
      @user2.serialized_private_key.include?("PRIVATE").should be true

      url = "http://" + writ.callback_url.split("/")[2] + "/"
      Person.where(:url => url).first.id.should == original_person_id
    end

   it 'should marshal a profile for a person' do
      #Create person
      person = Factory.create(:person)
      id = person.id
      person.profile = Profile.new(:first_name => 'bob', :last_name => 'billytown', :image_url => "http://clown.com")
      person.save

      #Cache profile for checking against marshaled profile
      old_profile = person.profile
      old_profile.first_name.should == 'bob'

      #Build xml for profile, clear profile
      xml = person.profile.to_diaspora_xml
      reloaded_person = Person.first(:id => id)
      reloaded_person.profile = nil
      reloaded_person.save(:validate => false)

      #Make sure profile is cleared
      Person.first(:id => id).profile.should be nil
      old_profile.first_name.should == 'bob'

      #Marshal profile
      @user.receive xml

      #Check that marshaled profile is the same as old profile
      person = Person.first(:id => person.id)
      person.profile.should_not be nil
      person.profile.first_name.should == old_profile.first_name
      person.profile.last_name.should  == old_profile.last_name
      person.profile.image_url.should  == old_profile.image_url
      end
  end
end

