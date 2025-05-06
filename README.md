# Mongoid::RelationsDirtyTracking

Mongoid extension for tracking changes on document relations.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'mongoid_relations_dirty_tracking'
```

## Version Support

The latest version of this gem is CI tested using:

- Mongoid 8.0+
- Ruby 2.7+
- Rails 7.0+

Please use earlier versions of this gem for legacy support.

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

## Disablement

Relations dirty tracking can be resource intensive,
hence you may wish to disable it dynamically.

#### When using .only?

If you query objects with the `.only?(*fields)` modifier, Mongoid
itself marks the objects as `readonly` and attempts to save them will fail.
In this case, relations dirty tracking is automatically disabled.

```ruby
Mongoid::RelationsDirtyTracking.disable do
  doc = SampleDocument.all.only(:title).first
  doc.foo = Foo.new(title: 'foo')
  doc.bars << Bar.new(title: 'bar')

  doc.relations_changed? # => false
  doc.relation_changes   # => {}
 
  doc.save! #=> raises Mongoid::Errors::ReadonlyDocument
end
```

#### Within a block scope

You may disable relations dirty tracking for a given block.
This is thread-safe and will use the [RequestStore gem](https://github.com/steveklabnik/request_store)
if it is included in your project.

```ruby
Mongoid::RelationsDirtyTracking.disable do
  doc = SampleDocument.create
  doc.foo = Foo.new(title: 'foo')
  doc.bars << Bar.new(title: 'bar')

  doc.relations_changed? # => false
  doc.relation_changes   # => {}
end
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Attribution

Created 2013 by David Sevcik

Maintenance from 2020 onward provided by [TableCheck](https://www.tablecheck.com/en/company/)
