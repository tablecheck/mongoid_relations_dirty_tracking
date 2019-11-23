# Mongoid::RelationsDirtyTracking

Mongoid extension for tracking changes on document relations.

## Installation

Add this line to your application's Gemfile:

    gem 'mongoid_relations_dirty_tracking', github: 'versative/mongoid_relations_dirty_tracking'

And then execute:

    $ bundle

## Usage

```ruby
class SampleDocument
  include Mongoid::Document
  include Mongoid::RelationsDirtyTracking

  embeds_one  :foo
  has_many    :bars

  field :title, type: String
end

doc = SampleDocument.create
doc.foo = Foo.new(title: 'foo')
doc.bars << Bar.new(title: 'bar')
doc.title = 'New title'

doc.relations_changed?      # => true
doc.relation_changes        # => {"foo" => [nil, {"_id"=>"524c35ad1ac1c23084000040", "title" => "foo"}], "bars" => [nil, [{"_id"=>"524c35ad1ac1c23084000083"}]]}
doc.changed_with_relations? # => true
doc.changes_with_relations  # => {"title" => [nil, "New title"], "foo" => [nil, {"_id"=>"524c35ad1ac1c23084000040", "title" => "foo"}], "bars" => [nil, [{"_id"=>"524c35ad1ac1c23084000083"}]]}

doc.save
doc.relations_changed?      # => false
doc.relation_changes        # => {}
doc.changed_with_relations? # => false
doc.changes_with_relations  # => {}
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
