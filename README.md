# EmbeddedRecord

[![Build Status](http://travis-ci.org/wojtekmach/embedded_record.png)](http://travis-ci.org/wojtekmach/embedded_record)

* http://github.com/wojtekmach/embedded\_record

## DESCRIPTION:

EmbeddedRecord is designed to do two things:

* Define records on a Class
* Embed one or many records (similiar to belongs\_to and
has\_and\_belongs\_to\_many associations)
* See example Rails app:
  [EmbeddedRecordExample](https://github.com/wojtekmach/embedded_record_example)

## SYNOPSIS:

Basic embeddable record usage:

```ruby
class Color
  include EmbeddedRecord::Record
  attribute :name
  attribute :hex

  record :red,   :name => "Red",   :hex => "#FF0000"
  record :green, :name => "Green", :hex => "#00FF00"
  record :blue,  :name => "Blue",  :hex => "#0000FF"
end

p Color.ids # => [:red, :green, :blue]
p Color.all # => [#<Color>, #<Color>, #<Color>]
Color.first
Color.last

blue = Color.find(:blue)
p blue.id    # => :blue

p blue.index # => 2
p blue.name  # => "Blue"
p blue.hex   # => "#0000FF"

p blue.is?(:red) # false
```

Embedding record:

```ruby
class Car
  attr_accessor :color_mask # integer id of a record
  include EmbeddedRecord
  embed_record :color
end

car = Car.new
car.color_id = :red
p car.color_mask # => 0
p car.color.name # => "Red"
```

Embedding records:

```ruby
class Car
  attr_accessor :colors_mask # integer bitmask of record ids
  include EmbeddedRecord
  embed_records :colors
end

car = Car.new
car.color_ids = [:red, :green]
p car.colors.first.name # => "Red"
p car.color_ids         # => [:red, :green]
p car.colors_mask       # => 3 (2**0 + 2**1)
```

## REQUIREMENTS:

None

## INSTALL:

* `gem install embedded_record`

## LICENSE:

(The MIT License)

Copyright (c) 2011 Wojciech Mach

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
