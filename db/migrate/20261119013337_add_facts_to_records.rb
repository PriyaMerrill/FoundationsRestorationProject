class AddFactsToRecords < ActiveRecord::Migration[8.1]
  def change
    # A short list of labelled facts shown "at a glance" on a record's page:
    # [ { "label" => "Born", "value" => "December 23, 1805, in Sharon, Vermont" }, ... ]
    %i[people places revelations].each do |table|
      add_column table, :facts, :jsonb, null: false, default: []
    end
  end
end
