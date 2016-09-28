```ruby
class PersonPage
  include FieldSerializer

  field :name do
    noko.css('.name')
  end

  field :start_date do
    noko.xpath("//span[@class='start-membership']")
  end

  # field :end_date, :noko, css: '.end-date'

  scope :social_media do
    noko.xpath('//h2[.="Sotsiaalmeedia"]/following-sibling::div[@class="group"]')
  end

  field :twitter do
    social_media.css('a.twitter/@href')
  end

end

person_page = PersonPage.new(noko: Nokogiri::HTML('<p class="name">Malcolm</p>'))

person_page.to_h
# => { name: 'Malcolm', start_date: '2016-09-28' }
```

```ruby
class AreaPage
  include FieldSerializer

  field :start_date do
    item.P571.value
  end

  field :end_date do
    item.P576.value
  end
end

area = AreaPage.new(item: Wikisnakker::Item.find('Q42'))
area.to_h
# => { name: 'Malcolm', start_date: '2016-09-28' }
```
