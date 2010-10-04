#   Copyright (c) 2010, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3.  See
#   the COPYRIGHT file.

module Diaspora
  module UserModules
    module Friending
      def send_friend_request_to(new_friend, aspect)
        raise "You are already friends with that person!" if self.friends.detect{
          |x| x.receive_url == new_friend.receive_url}
        writ = self.inscribe(new_friend, :into => aspect)
        salmon writ, :to => new_friend
        writ
      end
      def accept_friend_request(writ_id, aspect_id)
        writ = Writ.find_by_id(writ_id)
        pending_writs.delete(writ)
        inscribe writ.sender, :into => aspect_by_id(aspect_id)
      end

      def dispatch_friend_acceptance(request, requester)
        salmon request, :to => requester
        request.destroy unless request.callback_url.include? url
      end

      def accept_and_respond(friend_request_id, aspect_id)
        requester = Writ.find_by_id(friend_request_id).person
        reversed_request = accept_friend_request(friend_request_id, aspect_id)
        dispatch_friend_acceptance reversed_request, requester
      end

      def ignore_friend_request(friend_request_id)
        request = Writ.find_by_id(friend_request_id)
        person  = request.person

        self.pending_requests.delete(request)
        self.save

        person.save
        request.destroy
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
        Rails.logger.info("#{self.real_name} is unfriending #{bad_friend.inspect}")
        retraction = Retraction.for(self)
        salmon( retraction, :to => bad_friend)
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
        save
        aspect.save
      end

      def request_from_me?(request)
        pending_requests.detect{|req| (req.callback_url == person.receive_url) && (req.destination_url == person.receive_url)}
      end
    end
  end
end
