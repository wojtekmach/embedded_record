module EmbeddedRecord
  VERSION = "0.0.1"

  def self.included(klass)
    klass.extend self
  end

  ##
  # Options:
  #   - :class - Class to embed
  #   - :scope - Boolean wheter to install ActiveRecord scope
  def embed_record(name, options = {})
    raise ArgumentError, "Option :class is required" unless options[:class]

    klass = options[:class]
    attr = "#{name}_mask"
    all = klass.all

    define_method name do
      if val = send(attr)
        klass.all[val]
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
  #
  # Example:
  #
  #   class Shirt
  #     embed_records :colors, :class => Color, :singular => :color
  #   end
  #
  def embed_records(name, options = {})
    [:class, :singular].each do |opt|
      raise ArgumentError, "Option :#{opt} is required" unless options[opt]
    end

    singular = options[:singular]
    klass = options[:class]
    all_ids = klass.all.map { |obj| obj.id }
    attr = "#{name}_mask"

    define_method "#{singular}_ids=" do |ids|
      type_method = embed_id_type_method(klass)
      ids = ids.map(&type_method)
      self.send "#{attr}=",
        (ids & all_ids).map { |r| 2**all_ids.index(r) }.inject(0, :+)
    end

    define_method "#{singular}_ids" do
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
    klass = name.to_s.classify.constantize
    plural = name.to_s.pluralize

    send :scope, :"with_#{name.to_s.tableize}", lambda { |*ids|
      masks = ids.map { |id| klass.find(id).index }
      where("#{plural}_mask in (?)", masks)
    }
  end

  def embed_records_scope(name)
    klass = name.to_s.classify.constantize
    plural = name.to_s.pluralize

    send :scope, :"with_#{name.to_s.tableize}", lambda { |*ids|
      masks = ids.map { |id| 2 ** klass.find(id).index }.join(" | ")
      where("#{plural}_mask & (?)", masks)
    }
  end

private

  def embed_id_type_method(klass)
    klass.ids.first.is_a?(Symbol) ? :to_sym : :to_s
  end
end

module EmbeddedRecord::Record
  def self.included(klass)
    klass.extend ClassMethods
    klass.attribute :id
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
    ##
    # Returns Array of record attributes
    def attributes
      @attributes ||= []
    end

    ##
    # Returns Array of records ids
    def ids
      records.keys
    end

    ##
    # Returns record for a given id or nil
    def find(id)
      all.find { |obj| obj.id == id }
    end

    ##
    # Returns all records
    def all
      records.values
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
    def record(id, attrs = {})
      record = new
      record.send "id=", id
      attrs.each do |k, v|
        unless attributes.include? k
          raise ArgumentError, "Atrribute '#{k}' not found"
        end

        record.send "#{k}=", v
      end
      records[id] = record
    end

    ##
    # Defines a Symbol attribute for a record
    def attribute(name)
      attributes << name

      unless method_defined?(name)
        attr_accessor name
      end
    end

  private

    def records
      @records ||= {}
    end
  end
end
