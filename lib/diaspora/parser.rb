#   Copyright (c) 2010, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3.  See
#   the COPYRIGHT file.

module Diaspora
  module Parser
    def self.owner_id_from_xml(xml)
      doc = Nokogiri::XML(xml) { |cfg| cfg.noblanks }
      id = doc.xpath("//person_id").text.to_s
      Person.first(:id => id)
    end

    def self.parse_or_find_person_from_xml(xml, element = "person")
      doc = Nokogiri::XML(xml) { |cfg| cfg.noblanks }
      person_xml = doc.xpath("//#{element}").to_s
      person_id = doc.xpath("//#{element}/_id").text.to_s
      person = Person.first(:_id => person_id)
      person ? person : Person.from_xml( person_xml)
    end

    def self.from_xml(xml)
      doc = Nokogiri::XML(xml) { |cfg| cfg.noblanks }
      begin
        new_object = doc.root.name.camelize.constantize.from_xml doc.root.to_s

        if new_object.is_a? Post
          existing_object = new_object.class.find_by_id(new_object.id)
          existing_object ? (return existing_object) : (return new_object)
        end

        new_object

      rescue NameError => e
        if e.message.include? 'wrong constant name'
          Rails.logger.info "Not a real type: #{object.to_s}"
        end
        raise e
      end
    end
  end
end
