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
- Rails 7.1+

Please use earlier versions of this gem for legacy support.

## Usage

```ruby
class SampleDocument
  include Mongoid::Document
  include Mongoid::RelationsDirtyTracking

  embeds_one  :foo
  embeds_many :bars

  field :title, type: String
end

doc = SampleDocument.create
doc.foo = Foo.new(title: 'foo')
doc.bars << Bar.new(title: 'bar')
doc.title = 'New title'

doc.relations_changed?      # => true
doc.relation_changes        # => {"foo" => [nil, {"_id"=>"524c35ad1ac1c23084000040", "title" => "foo"}], "bars" => [[], [{"_id"=>"524c35ad1ac1c23084000083", "title"=>"bar"}]]}
doc.changed_with_relations? # => true
doc.changes_with_relations  # => {"title" => [nil, "New title"], "foo" => [nil, {"_id"=>"524c35ad1ac1c23084000040", "title" => "foo"}], "bars" => [[], [{"_id"=>"524c35ad1ac1c23084000083", "title"=>"bar"}]]}

doc.save
doc.relations_changed?      # => false
doc.relation_changes        # => {}
doc.changed_with_relations? # => false
doc.changes_with_relations  # => {}
```

By default only **embedded** relations (`embeds_one`, `embeds_many`) are
tracked. To also track referenced relations (`has_one`, `has_many`,
`has_and_belongs_to_many`, `belongs_to`), opt in per class:

```ruby
class SampleDocument
  include Mongoid::Document
  include Mongoid::RelationsDirtyTracking

  embeds_many :tags
  has_many    :comments
  belongs_to  :author

  relations_dirty_tracking track_referenced: true
end
```

You can still narrow tracking further with `:only` and `:except`. These
filters are applied **within** the set of trackable relations selected by
`:track_referenced`:

```ruby
relations_dirty_tracking only: %i[tags]                            # embedded only, only :tags
relations_dirty_tracking only: %i[tags comments], track_referenced: true
relations_dirty_tracking except: %i[tags], track_referenced: true  # everything except :tags
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

## Upgrading from 0.x

**v1.0.0 narrowed the default trackables to embedded relations only.** Earlier
versions tracked every kind of relation (embedded, has_one, has_many, HABTM,
belongs_to) by default. We changed the default because tracking referenced
relations forces those associations to be loaded on every `after_initialize`
and `after_save` callback — a significant cost when documents are read in bulk
or via background jobs.

### How to tell if you are affected

You are affected if any class in your application includes
`Mongoid::RelationsDirtyTracking` **and** relies on dirty tracking for
`has_one`, `has_many`, `has_and_belongs_to_many`, or `belongs_to` associations.
A class is *not* affected if it only uses dirty tracking for `embeds_one` /
`embeds_many` associations.

A quick way to audit your codebase:

```bash
grep -rln "include Mongoid::RelationsDirtyTracking" app/ lib/
```

For each match, check whether the class actually consumes `relation_changes` /
`changes_with_relations` / `relations_changed?` for a referenced relation
(typically read by audit logs, `mongoid-history` callbacks, push-sync hooks,
etc.).

### Restoring the v0.x behaviour

If you were depending on referenced relation tracking, add
`track_referenced: true` to the macro call:

```ruby
# Before (v0.x — tracked everything by default)
class Order
  include Mongoid::Document
  include Mongoid::RelationsDirtyTracking

  embeds_many :items
  has_many    :payments
end

# After (v1.0 — restore previous behaviour for this class)
class Order
  include Mongoid::Document
  include Mongoid::RelationsDirtyTracking

  embeds_many :items
  has_many    :payments

  relations_dirty_tracking track_referenced: true
end
```

If you already call `relations_dirty_tracking` with `:only` or `:except`, add
the option to that call:

```ruby
# Before (v0.x)
relations_dirty_tracking only: %i[items payments]

# After (v1.0)
relations_dirty_tracking only: %i[items payments], track_referenced: true
```

### When you can leave the new default

Most callers can leave the new default and benefit from the speedup. Common
cases where referenced tracking is *not* needed:

- You only track embedded sub-documents (e.g. line items, addresses).
- You use the gem to invalidate a cache or trigger a webhook when an embedded
  collection changes.
- Your referenced relations are also tracked through their own
  `mongoid-history` / audit hooks on the **referenced** side, making the
  parent-side tracking redundant.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Attribution

Created 2013 by David Sevcik

Maintenance from 2020 onward provided by [TableCheck](https://www.tablecheck.com/en/company/)
