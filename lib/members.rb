# frozen_string_literal: true
require_rel 'page'

class Riigikogu
  class MemberBox < Riigikogu::Page
    field :name do
      noko.css('h3').text.tidy
    end

    field :url do
      URI.escape(noko.css('h3 a/@href').text)
    end

    field :email do
      noko.css('li a[href*="mailto"]').text
    end
  end

  class Members < Riigikogu::Page
    field :members do
      noko.css('ul.profile-list li.item').map do |mp|
        fragment mp => MemberBox
      end
    end
  end
end
