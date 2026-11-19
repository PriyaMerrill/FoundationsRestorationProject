class AddStoryToEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :background, :text
    add_column :events, :account, :text
    add_column :events, :significance, :text
  end
end
