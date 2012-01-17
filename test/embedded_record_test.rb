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

class Car
  include EmbeddedRecord
  embed_record :color
  attr_accessor :color_mask
end

class Shirt
  include EmbeddedRecord
  embed_records :colors
  attr_accessor :colors_mask
end

describe EmbeddedRecord::Record do
  before do
    @cls = Class.new do
      include EmbeddedRecord::Record
      attribute :name
    end
  end

  it "::attributes returns names pf attributes" do
    @cls.attribute :val
    @cls.attributes.must_equal [:id, :name, :val]
  end

  it "::all returns array of records" do
    @cls.record 1
    @cls.record 2

    all = @cls.all
    all.must_be_kind_of Array
    all.size.must_equal 2

    all.each_with_index do |record, idx|
      record.must_be_kind_of @cls
      record.id.must_equal idx + 1
    end
  end

  it "::ids returns array of records ids" do
    @cls.record :one
    @cls.record :two
    @cls.ids.must_equal [:one, :two]
  end

  describe "::id_class" do
    it "returns class of id attribute" do
      @cls.record :one
      @cls.id_class.must_equal Symbol
    end

    it "returns nil when no record is present" do
      @cls.id_class.must_equal nil
    end
  end

  describe "::record" do
    it "creates a new record" do
      @cls.ids.must_equal []
      @cls.record :one
      @cls.ids.must_equal [:one]
    end

    it "accepts symbol as id" do
      @cls.record(:one)
      @cls.id_class.must_equal Symbol
    end

    it "accepts string as id" do
      @cls.record "two"
      @cls.id_class.must_equal String
    end

    it "accepts integer as id" do
      @cls.record 3
      @cls.id_class.must_equal Fixnum
    end

    it "raises error when id is not symbol, string, integer or nil" do
      lambda { @cls.record 1.0 }.must_raise ArgumentError
    end
  end

  describe "#find" do
    it "returns record with a given id" do
      @cls.record :one
      @cls.record :two
      one = @cls.find(:one)
      one.must_be_kind_of @cls
      one.id.must_equal :one
    end

    it "returns nil when no record is found for a given id" do
      @cls.record :one
      @cls.find(:two).must_equal nil
    end
  end

  it "::first returns first record" do
    @cls.first.must_equal nil
    @cls.record 1
    @cls.record 2
    @cls.first.id.must_equal 1
  end

  it "::last returns last record" do
    @cls.first.must_equal nil
    @cls.record 1
    @cls.record 2
    @cls.last.id.must_equal 2
  end

  describe "#is?" do
    before { @cls.record :good}

    it "returns true for good id" do
      @cls.find(:good).is?(:good).must_equal true
    end

    it "returns false for bad id" do
      @cls.find(:good).is?(:bad).must_equal false
    end
  end

  it "#index returns record index in record set" do
    3.times do |i|
      @cls.record i
      @cls.find(i).index.must_equal i
    end
  end

  it "attributes are frozen" do
    @cls.record 1, :name => "Hello"
    rec = @cls.find(1)
    lambda { rec.name << " World!" }.must_raise RuntimeError, TypeError
  end

  describe "#null_record" do
    it "returns nil if no null object is set" do
      @cls.null_record.must_equal nil
    end

    it "returns null object if it is set" do
      @cls.record nil, :name => "Empty"

      @cls.null_record.name.must_equal "Empty"
      @cls.null_record.id.must_equal nil
      @cls.all.wont_include @cls.null_record
    end
  end
end

describe EmbeddedRecord do
  before do
    @cls = Class.new do
      include EmbeddedRecord
    end

    @rec_class = Class.new do
      include EmbeddedRecord::Record
    end
  end

  describe "::embed_record" do
    it "defines <name>, <name>_id, <name>_id= methods" do
      @cls.embed_record :foo, :class => @rec_class
      @cls.method_defined?(:foo).must_equal true
      @cls.method_defined?(:foo_id).must_equal true
      @cls.method_defined?(:foo_id=).must_equal true
    end

    it "guesses Class based on the name" do
      @cls.embed_record :color
      @cls.method_defined?(:color_id).must_equal true
    end

    it "raises error when embedding class without Record module" do
      cls = Class.new
      lambda {
        @cls.embed_record :foo, :class => cls
      }.must_raise ArgumentError
    end

    it "allows to set :mask_attr" do
      @cls.embed_record :foo, :class => @rec_class, :mask_attr => :val
      @cls.class_eval do
        attr_accessor :val
      end

      @rec_class.record :a
      @rec_class.record :b
      @obj = @cls.new
      @obj.foo_id = :b
      @obj.foo.id.must_equal :b
      @obj.val.must_equal 1
    end
  end

  describe "with embedded record" do
    before do
      @car = Car.new
    end

    describe "#<name>_id" do
      it "sets the record mask" do
        @car.color_id = :blue
        @car.color_mask.must_equal 2
      end

      describe "with argument that is not the same type as id" do
        before do
          tmp = @rec_class
          @cls.class_eval do
            embed_record :foo, :class => tmp
            attr_accessor :foo_mask
          end
          @obj = @cls.new
        end

        it "converts argument when id is symbol" do
          @rec_class.record :one
          @obj.foo_id = "one"
          @obj.foo_id.must_equal :one
        end

        it "converts argument when id is string" do
          @rec_class.record "one"
          @obj.foo_id = :one
          @obj.foo_id.must_equal "one"
        end

        it "converts argument when id is integer" do
          @rec_class.record 1
          @obj.foo_id = "1"
          @obj.foo_id.must_equal 1
        end
      end
    end

    it "#<name>_id returns id of a record" do
      @car.color_mask = 2
      @car.color_id.must_equal :blue
    end

    it "#<name> returns record" do
      @car.color_mask = 2
      @car.color.id.must_equal :blue
    end

    it "#<name> returns nil when no record is set" do
      @car.color.must_equal nil
    end

    describe "with null record" do
      it "#<name> returns null record when no record is set" do
        rec_class = Class.new(Color) do
          attribute :name
          record nil, :name => "Empty"
        end

        @cls.class_eval do
          attr_accessor :foo_mask
          embed_record :foo, :class => rec_class
        end

        @cls.new.foo.name.must_equal "Empty"
      end
    end
  end

  describe "::embed_records" do
    before do
      @rec_class = Class.new do
        include EmbeddedRecord::Record
      end
    end

    it "defines <plural>, <singular>_ids, <singular>_ids= methods" do
      @cls.embed_records :foos, :class => @rec_class

      @cls.method_defined?(:foos).must_equal true
      @cls.method_defined?(:foo_ids).must_equal true
      @cls.method_defined?(:foo_ids=).must_equal true
    end

    it "guesses Class based on the name" do
      @cls.embed_records :colors
      @cls.method_defined?(:color_ids).must_equal true
    end

    it "raises error when embedding class without Record module" do
      cls = Class.new
      lambda {
        @cls.embed_records :foo, :class => cls
      }.must_raise ArgumentError
    end

    it "allows to set :mask_attr" do
      @rec_class.record :a
      @rec_class.record :b
      @rec_class.record :c

      @cls.embed_records :foos, :class => @rec_class, :mask_attr => :val
      @cls.class_eval do
        attr_accessor :val
      end

      @obj = @cls.new
      @obj.foo_ids = [:a, :c]
      @obj.foos.map(&:id).must_equal [:a, :c]
      @obj.val.must_equal 2**0 + 2**2
    end
  end

  describe "with embedded records" do
    before do
      @obj = Shirt.new
    end

    describe "#<name>_ids=" do
      it "sets the mask" do
        @obj.color_ids = [:red, :blue]
        @obj.colors_mask.must_equal(2**0 + 2**2)
      end

      it "converts argument to id's type" do
        @obj.color_ids = %w(red blue)
        @obj.color_ids.must_equal [:red, :blue]
      end
    end

    it "#<name>_ids returns ids of records" do
      @obj.colors_mask = 2**1 + 2**2
      @obj.color_ids = [:green, :blue]
    end

    it "#<name> returns records" do
      @obj.color_ids = [:green, :blue]
      @obj.colors.map(&:id).must_equal [:green, :blue]
    end
  end
end
