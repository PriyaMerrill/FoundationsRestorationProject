class AddStoryToRecords < ActiveRecord::Migration[8.1]
  def change
    %i[people places revelations].each do |table|
      add_column table, :story, :jsonb, default: [], null: false
    end
  end
end
