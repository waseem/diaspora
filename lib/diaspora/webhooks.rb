#   Copyright (c) 2010, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.

module Diaspora
  module Webhooks

    def to_diaspora_xml
      to_xml.to_s
    end

  end
end
