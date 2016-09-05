require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    query_params = params.map do |param, value|
      "#{param} = ?"
    end.join(" AND ")
    query = DBConnection.execute(<<-SQL, *params.values)
      SELECT *
      FROM #{self.table_name}
      WHERE #{query_params}
    SQL

    parse_all(query)
  end
end

class SQLObject extend Searchable
end
