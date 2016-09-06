require_relative '03_associatable'

# Phase IV
module Associatable
  # Remember to go back to 04_associatable to write ::assoc_options

  def has_one_through(name, through_name, source_name)
    that = self
    define_method(name) do
      through_options = that.assoc_options[through_name]
      source_options = through_options.model_class.assoc_options[source_name]
      fk = self.send(through_options.foreign_key)
      query = DBConnection.execute(<<-SQL, fk)
        SELECT #{source_name}s.*
        FROM #{through_name}s
        JOIN #{source_name}s ON #{through_name}s.#{source_options.foreign_key} = #{source_name}s.#{source_options.primary_key}
        WHERE #{through_name}s.#{through_options.primary_key} = ?
      SQL
      source_options.model_class.parse_all(query).first
    end

  end
end
