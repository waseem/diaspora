#   Copyright (c) 2010, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.

module Diaspora
  module UserModules
    module Friending
      def inscribe(person, options)
        raise "Already friends with that person!" if friends.member?(person)
        options[:from] = self.person
        options[:to] = person.receive_url
        writ = Writ.instantiate options
        activate_friend(person, options[:into])
        writ
      end

      def send_friend_request_to(new_friend, aspect)
        writ = self.inscribe(new_friend, :into => aspect)
        push_to_people(writ, [new_friend])
        writ
      end

      def receive_writ(writ)
        Rails.logger.info("receiving writ #{writ.to_json}")
        return if friends.include? writ.sender #TODO Put this info in a notification queue
        writ.save
        self.pending_writs << writ
        self.save
        Rails.logger.info("#{self.real_name} has received a writ")
      end

      def unfriend(bad_friend)
        remove_friend(bad_friend)
      end

      def remove_friend(bad_friend)
        raise "Friend not deleted" unless self.friend_ids.delete( bad_friend.id )
        aspects.each{|aspect|
          aspect.person_ids.delete( bad_friend.id )}
        self.save

        self.raw_visible_posts.find_all_by_person_id( bad_friend.id ).each{|post|
          self.visible_post_ids.delete( post.id )
          post.user_refs -= 1
          (post.user_refs > 0 || post.person.owner.nil? == false) ?  post.save : post.destroy
        }
        self.save

        bad_friend.save
      end

      def unfriended_by(bad_friend)
        Rails.logger.info("#{self.real_name} is being unfriended by #{bad_friend.inspect}")
        remove_friend bad_friend
      end

      def activate_friend(person, aspect)
        aspect.people << person
        friends << person
        ignore_writ(writs_from(person).first)
        save
        aspect.save
      end

      def writs_from(person)
        self.pending_writs.select{|w| w.sender == person }
      end

      def ignore_writ(writ)
        self.pending_writs -= [writ]
        save
      end

    end
  end
end
