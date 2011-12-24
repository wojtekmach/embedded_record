require "virtus"

module EmbeddedRecord
  VERSION = "0.0.5"

  def self.included(klass)
    klass.extend self
  end

  ##
  # Options:
  #   - class - Class to embed
  #   - scope - Boolean wheter to install ActiveRecord scope
  #   - mask_attr - Symbol attribute for storing bitmask.
  #                  Defaults to <name>_mask
  def embed_record(name, options = {})
    klass = options[:class] || EmbeddedRecord.constantize(name.to_s)

    unless klass.included_modules.include? Record
      raise ArgumentError, "Class must include EmbeddedRecord::Record"
    end

    attr = options[:mask_attr] || "#{name}_mask"

    define_method name do
      if val = send(attr)
        klass.all[val]
      elsif klass.null_record
        klass.null_record
      end
    end

    define_method "#{name}_id" do
      if val = send(attr)
        klass.all[val].id
      end
    end

    define_method "#{name}_id=" do |id|
      type_method = embed_id_type_method(klass)
      index = klass.all.index { |obj| obj.id == id.send(type_method) }
      send "#{attr}=", index
      index
    end

    if options[:scope] == true
      embed_record_scope name
    end
  end

  ##
  # Options:
  #   - class - Class of record
  #   - singular - singular form of name
  #   - mask_attr - Symbol attribute for storing bitmask.
  #                 Defaults to <name>_mask
  #
  # Example:
  #
  #   class Shirt
  #     embed_records :colors, :class => Color, :singular => :color
  #   end
  #
  def embed_records(name, options = {})
    singular = options[:singular] || EmbeddedRecord.singularize(name.to_s)
    klass = options[:class] || EmbeddedRecord.constantize(singular.to_s)

    unless klass.included_modules.include? Record
      raise ArgumentError, "Class must include EmbeddedRecord::Record"
    end

    attr = options[:mask_attr] || "#{name}_mask"

    define_method "#{singular}_ids=" do |ids|
      all_ids = klass.all.map &:id
      type_method = embed_id_type_method(klass)
      ids = ids.map(&type_method)
      self.send "#{attr}=",
        (ids & all_ids).map { |r| 2**all_ids.index(r) }.inject(0, :+)
    end

    define_method "#{singular}_ids" do
      all_ids = klass.all.map &:id
      all_ids.reject { |r| ((send(attr) || 0) & 2**all_ids.index(r)).zero? }
    end

    define_method name do
      ids = send("#{singular}_ids")

      klass.all.select do |obj|
        ids.include? obj.id
      end
    end

    if options[:scope] == true
      embed_records_scope name
    end
  end

  def embed_record_scope(name)
    klass = EmbeddedRecord.constantize(name)

    send :scope, :"with_#{name}", lambda { |*ids|
      masks = ids.map { |id| klass.find(id).index }
      where("#{name}_mask in (?)", masks)
    }
  end

  def embed_records_scope(name)
    klass = EmbeddedRecord.constantize(name)

    send :scope, :"with_#{name}", lambda { |*ids|
      masks = ids.map { |id| 2 ** klass.find(id).index }.join(" | ")
      where("#{name}_mask & (?)", masks)
    }
  end

private

  def embed_id_type_method(klass)
    case klass.ids.first
    when Symbol then :to_sym
    when Fixnum then :to_i
    else :to_s
    end
  end

  def self.constantize(str)
    if defined?(ActiveSupport::Inflector)
      return ActiveSupport::Inflector.constantize(
        ActiveSupport::Inflector.classify(str))
    end

    # Stolen from ActiveSupport::Inflector
    cls = str.to_s.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
    Kernel.const_get(cls)
  end

  def self.singularize(str)
    if defined?(ActiveSupport::Inflector)
      return ActiveSupport::Inflector.singularize(str)
    end

    str.to_s[0..-2]
  end 
 
  def self.pluralize(str)
    if defined?(ActiveSupport::Inflector)
      return ActiveSupport::Inflector.pluralize(str)
    end

    str.to_s + "s"
  end
end

module EmbeddedRecord::Record
  def self.included(klass)
    klass.extend ClassMethods
    klass.class_eval do
      include Virtus
    end
  end

  ##
  # Returns true if record's id is the same as argument or false otherwise
  def is?(id)
    self.id == id
  end

  ##
  # Returns Integer index of the record in the records set
  def index
    self.class.all.index(self)
  end

  module ClassMethods
    def attribute_names
      attributes.map(&:name)
    end

    ##
    # Returns Array of records ids
    def ids
      @keys ||= []
    end

    ##
    # Returns record for a given id or nil
    def find(id)
      all.find { |obj| obj.id == id }
    end

    ##
    # Returns all records
    def all
      @records ||= []
    end

    ##
    # Returns first record
    def first
      all.first
    end

    ##
    # Returns last record
    def last
      all.last
    end

    ##
    # Defines a record with an id and Hash of attributes.
    #
    #   id - must be symbol, string, integer or nil for null record
    def record(id, attrs = {})
      unless attribute_names.include?(:id)
        raise RuntimeError, "id attribute not defined"
      end

      record = new
      record.send "id=", id
      attrs.each do |k, v|
        unless attribute_names.include? k
          raise ArgumentError, "Atrribute '#{k}' not found"
        end

        record.send "#{k}=", v.freeze
      end

      if id == nil
        @null_record = record
      else
        ids << id
        all << record
      end
    end

    ##
    # Returns null record, a record which id is nil
    #
    # Example:
    #
    #   class Foo
    #     record nil, :name => "Empty"
    #   end
    #
    #   Foo.null_record.name # => "Empty"
    def null_record
      @null_record
    end
  end
end
