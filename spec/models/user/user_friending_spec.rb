#   Copyright (c) 2010, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3.  See
#   the COPYRIGHT file.

require 'spec_helper'

describe User do
   before do
      @user = Factory.create(:user)
      @friend = Factory.create(:person)
      @aspect = @user.aspect(:name => 'heroes')
   end

  describe 'sending writs' do
    it "should place the target in an aspect" do
      @user.inscribe @friend, :into => @aspect

      @aspect.reload
      @aspect.people.should include @friend
    end

    it "should be able to send a response to a writ"
    it 'should be able to ignore a writ'
    it 'should not be able to friend request an existing friend' do
      @user.friends << @friend
      @user.save

      proc {@user.inscribe @friend, :into => @aspect}.should raise_error
    end
  end

  describe 'unfriending' do
    before do
      @user2 = Factory.create :user
      @aspect2 = @user2.aspect(:name => "Gross people")

      friend_users(@user, @aspect, @user2, @aspect2)
      @user.reload
      @user2.reload
      @aspect.reload
      @aspect2.reload
    end

    it 'should unfriend the other user on the same seed' do
      @user.friends.count.should == 1
      @user2.friends.count.should == 1

      @user2.unfriend @user.person
      @user2.friends.count.should be 0

      @user.unfriended_by @user2.person

      @aspect.reload
      @aspect2.reload
      @aspect.people.count.should == 0
      @aspect2.people.count.should == 0
    end
    context 'with a post' do
      before do
        @message = @user.post(:status_message, :message => "hi", :to => @aspect.id)
        @user2.receive @message.to_diaspora_xml.to_s
        @user2.unfriend @user.person
        @user.unfriended_by @user2.person
        @aspect.reload
        @aspect2.reload
        @user.reload
        @user2.reload
      end
      it "deletes the unfriended user's posts from visible_posts" do
        @user.raw_visible_posts.include?(@message.id).should be_false
      end
      it "deletes the unfriended user's posts from the aspect's posts" do
        pending "We need to implement this"
        @aspect2.posts.include?(@message).should be_false
      end
    end
  end
end
