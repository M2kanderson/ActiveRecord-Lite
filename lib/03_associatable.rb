require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    self.class_name.constantize
  end

  def table_name
    self.class_name.underscore + "s"
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    @name = name.to_s
    @class_name = options[:class_name] ? options[:class_name] : name.to_s.camelcase
    @primary_key = options[:primary_key] ? options[:primary_key] : :id
    @foreign_key = options[:foreign_key] ? options[:foreign_key] : "#{name}_id".to_sym

  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    @name = name.to_s
    # if(options.empty?)
    #   @class_name = name.to_s.camelcase.singularize
    #   @primary_key = :id
    #   @foreign_key = "#{self_class_name.underscore}_id".to_sym
    # else
    #   @class_name = options[:class_name]
    #   @foreign_key = options[:foreign_key]
    #   @primary_key = options[:primary_key]
    # end

    @class_name = options[:class_name] ? options[:class_name] : name.to_s.camelcase.singularize
    @primary_key = options[:primary_key] ? options[:primary_key] : :id
    @foreign_key = options[:foreign_key] ? options[:foreign_key] : "#{self_class_name.underscore}_id".to_sym
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)

    define_method(name) do
      fk = self.send(options.foreign_key)
      mc = options.model_class
      mc.where({options.primary_key => fk }).first
    end
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self.to_s, options)
    define_method(name) do
      mc = options.model_class
      pk = self.send(options.primary_key)
      mc.where({options.foreign_key => pk })
    end
  end

  def assoc_options
    # Wait to implement this in Phase IVa. Modify `belongs_to`, too.
  end
end

class SQLObject extend Associatable
  # Mixin Associatable here...
end
