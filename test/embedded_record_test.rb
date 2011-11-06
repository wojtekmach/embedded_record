gem "minitest"
require "minitest/spec"
require "minitest/autorun"
require "embedded_record"

class Color
  include EmbeddedRecord::Record

  attribute :name

  record :red,   :name => "Red"
  record :green, :name => "Green"
  record :blue,  :name => "Blue"
end

describe "Object with EmbeddedRecord::Record" do
  it "#is? returns true if id is the same" do
    Color.find(:green).is?(:green).must_equal true
  end

  it "#is? returns false if id is not the same" do
    Color.find(:green).is?(:red).must_equal false
  end

  it "#index return record index in record set" do
    Color.find(:red).index.must_equal 0
    Color.find(:green).index.must_equal 1
    Color.find(:blue).index.must_equal 2
  end
end

describe "Class with EmbeddedRecord::Record" do
  it "::attributes returns names of record attributes" do
    Color.attributes.must_equal [:id, :name]
  end

  it "::all returns all records" do
    all = Color.all
    all.must_be_kind_of Array
    all.size.must_equal 3
    all.first.must_be_kind_of Color
    all.first.name.must_equal "Red"
  end

  it "::ids returns records ids" do
    Color.ids.must_equal [:red, :green, :blue]
  end

  it "::find returns record with specified id" do
    Color.find(:green).id.must_equal :green
  end

  it "::find returns nil when no record is found for an id" do
    Color.find(:bad).must_equal nil
  end

  it "::first returns first record" do
    Color.first.id.must_equal :red
  end

  it "::last returns last record" do
    Color.last.id.must_equal :blue
  end
end

describe "Class with EmbeddedRecord" do
  before do
    @cls = Class.new
    @cls.send :include, EmbeddedRecord
  end

  it "#embed_record defines <name>, <name>_id, <name>_id= methods" do
    @cls.embed_record :color
    @cls.method_defined?(:color).must_equal true
    @cls.method_defined?(:color_id).must_equal true
    @cls.method_defined?(:color_id=).must_equal true
  end

  it "#embed_records defines <name>, <name>_ids, <name>_ids= methods" do
    @cls.embed_records :colors
    @cls.method_defined?(:colors).must_equal true
    @cls.method_defined?(:color_ids).must_equal true
    @cls.method_defined?(:color_ids=).must_equal true
  end
end

class Car
  include EmbeddedRecord
  embed_record :color, :class => Color
  attr_accessor :color_mask
end

describe "Object embedding record" do
  before do
    @car = Car.new
  end

  it "#<name>_id= sets the index of a record" do
    @car.color_id = :green
    @car.color_mask.must_equal Color.find(:green).index
  end

  it "#<name>_id returns id of a record" do
    @car.color_mask = Color.find(:blue).index
    @car.color_id.must_equal :blue
  end

  it "#<name> returns record" do
    @car.color_mask = Color.find(:blue).index
    @car.color.must_equal Color.find(:blue)
  end
end

class Shirt
  include EmbeddedRecord
  embed_records :colors, :class => Color, :singular => "color"
  attr_accessor :colors_mask
end

describe "Object embedding records" do
  before do
    @shirt = Shirt.new
  end

  it "#<name>_ids= sets the indices of records" do
    @shirt.color_ids = [:red, :blue]
    @shirt.colors_mask.must_equal(2**0 + 2**2)
  end

  it "#<name>_ids returns ids of records" do
    @shirt.colors_mask = 2**1 + 2**2
    @shirt.color_ids = [:green, :blue]
  end

  it "#<name> returns records" do
    @shirt.color_ids = [:green, :blue]
    @shirt.colors.must_equal [Color.find(:green), Color.find(:blue)]
  end
end
