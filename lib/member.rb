# frozen_string_literal: true
require_rel 'page'

class Riigikogu
  class Member < Riigikogu::Page
    field :id do
      url.split('/')[7]
    end

    field :name do
      at_css('.page-header h1')
    end

    field :faction do
      at_css('.content a[href*="/fraktsioonid/"]')
    end

    field :committees do
      at_css('.content a[href*="/komisjonid"]')
    end

    field :image do
      absolute_link(at_css('.profile-photo img/@src')).to_s
    end

    field :phone do
      at_xpath('//span[contains(@class,"icon-tel")]/following-sibling::text()')
    end

    field :email do
      at_xpath('//span[contains(@class,"icon-mail")]/following-sibling::text()')
    end

    field :facebook do
      at_css('a.facebook/@href', scope: social_media)
    end

    field :twitter do
      at_css('a.twitter/@href', scope: social_media)
    end

    field :source do
      url
    end

    private

    def social_media
      noko.xpath('//h2[.="Sotsiaalmeedia"]/following-sibling::div[@class="group"]')
    end
  end
end
