```
class PersonPage
    include FieldSerializer

    field :name do 
        css('.name')
    end

    field :start_date do
        xpath('')
    end
end

person_page = PersonPage.new(html: '<p class="name">Malcolm</p>')

person_page.to_h 
# => { name: 'Malcolm' }

```