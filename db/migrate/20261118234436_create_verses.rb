class CreateVerses < ActiveRecord::Migration[8.1]
  def change
    # The text of a revelation, one row per verse.
    create_table :verses do |t|
      t.references :revelation, null: false, foreign_key: true
      t.integer :number, null: false
      t.text :text, null: false
      t.timestamps
    end
    add_index :verses, [ :revelation_id, :number ], unique: true
  end
end
