#   Copyright (c) 2010, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
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

    it 'should not be able to inscribe an existing friend' do
      @user.inscribe @friend, :into => @aspect
      proc {@user.inscribe @friend, :into => @user.aspect(:name => 'kaboom')}.should raise_error
    end
  end

  describe "receiving writs" do
    before do
      @admirer = Factory.create(:user)
      @user = Factory.create(:user)
      @writ_count = @user.pending_writs.count
      writ = @admirer.inscribe @user, :into => @admirer.aspect(:name => 'people I admire')
      @user.receive(writ.to_diaspora_xml)
      @user.reload
      @admirer.reload
    end
    
    it "should have a pending writ" do
      @user.pending_writs.count.should == @writ_count + 1
      @user.pending_writs.first.sender.id.should == @admirer.person.id
    end

    it "should be able to send a response to a writ" do
      @user.inscribe @user.pending_writs.first.sender, :into => @user.aspect
      @user.pending_writs.count.should == @writ_count
    end

    it 'does not delete other pending writs' do
      user3 = Factory.create(:user)
      @user.receive(user3.inscribe(@user, :into => user3.aspect(:name => "skaters")).to_diaspora_xml)

      @user.inscribe @user.pending_writs.first.sender, :into => @user.aspect
      @user.pending_writs.count.should == @writ_count + 1
    end

    it "does not create a second pending writ" do
      @user.inscribe @user.pending_writs.first.sender, :into => @user.aspect
      @admirer.pending_writs.should be_empty
    end

    it 'should be able to ignore a writ' do
      @user.ignore_writ @user.pending_writs.first
      @user.pending_writs.count.should == @writ_count
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
        @aspect2.posts.include?(@message).should be_false
      end
    end
  end
end
