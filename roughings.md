
```ruby
class PersonPage
  include FieldSerializer
  include HTMLMethods

  field :name do
    html.css('.name')
  end

  field :start_date do
    html.xpath("//span[@class='start-membership']")
  end
end

person_page = PersonPage.new(html: '<p class="name">Malcolm</p>')

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
