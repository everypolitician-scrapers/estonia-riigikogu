# frozen_string_literal: true
require_rel 'page'

class Riigikogu
  class Members < Riigikogu::Page
    field :members do
      noko.css('ul.profile-list li.item').map do |mp|
        {
          name:  mp.css('h3').text.tidy,
          url:   URI.escape(mp.css('h3 a/@href').text),
          email: mp.css('li a[href*="mailto"]').text,
        }
      end
    end
  end
end
