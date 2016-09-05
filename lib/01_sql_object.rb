require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    unless(@columns)
      query = DBConnection.execute2(<<-SQL)
      SELECT *
      FROM #{table_name}
      SQL
      @columns = query.first.map(&:to_sym)
    end
    @columns
  end

  def self.finalize!
    columns.each do |column|
      define_method(column) do
        attributes[column]
      end

      define_method("#{column}=") do |value|
        attributes[column] = value
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.name.pluralize.downcase
  end

  def self.all
    parse_all(DBConnection.execute("SELECT * FROM #{table_name}"))
  end

  def self.parse_all(results)
    objects = []
    results.each do |result|
      objects << self.new(result)
    end
    objects
  end

  def self.find(id)
    query = DBConnection.execute("SELECT * FROM #{table_name} WHERE id=?", id).first
    if(query)
      return self.new(query)
    end
    query
  end

  def initialize(params = {})
    params.each do |param, value|
      if(self.respond_to?("#{param}="))
        self.send("#{param}=",value)
      else
        raise "unknown attribute '#{param}'"
      end
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    @attributes.values
  end

  def insert
    table_name = self.class.table_name
    columns = self.class.columns.drop(1)
    col_names = columns.map(&:to_s).join(",")
    question_marks = (["?"] * columns.length).join(",")
    DBConnection.execute(<<-SQL, *attribute_values)
    INSERT INTO #{table_name} (#{col_names})
    VALUES (#{question_marks})
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update
    table_name = self.class.table_name
    id = self.id
    columns = self.class.columns.drop(1)
    col_names = columns.map do |column|
      "#{column} = ?"
    end.join(", ")

    DBConnection.execute(<<-SQL, *attribute_values[1..-1], id)
    UPDATE #{table_name}
    SET #{col_names}
    WHERE id = ?
    SQL
  end

  def save
    if(id.nil?)
      insert
    else
      update
    end
  end
end
