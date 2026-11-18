class CreateHistoricalDatabase < ActiveRecord::Migration[8.1]
  def change
    # --- Core records ---

    create_table :places do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :modern_name
      t.string :state
      t.decimal :latitude, precision: 9, scale: 6
      t.decimal :longitude, precision: 9, scale: 6
      t.string :kinds, array: true, null: false, default: []
      t.text :summary
      t.text :significance
      t.integer :start_year
      t.integer :end_year
      t.integer :trail_order
      t.timestamps
    end
    add_index :places, :slug, unique: true

    create_table :people do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.date :birth_date
      t.date :death_date
      t.string :roles
      t.text :biography
      t.jsonb :clues, null: false, default: []
      t.timestamps
    end
    add_index :people, :slug, unique: true

    create_table :events do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.date :start_date, null: false
      t.date :end_date
      t.string :date_precision, null: false, default: "exact"
      t.string :category, null: false
      t.string :period, null: false
      t.text :summary
      t.text :context
      t.references :place, foreign_key: true
      t.timestamps
    end
    add_index :events, :slug, unique: true
    add_index :events, :start_date
    add_index :events, :category
    add_index :events, :period

    create_table :revelations do |t|
      t.integer :section_number
      t.string :title, null: false
      t.string :slug, null: false
      t.date :received_on
      t.string :date_precision, null: false, default: "exact"
      t.text :summary
      t.string :subjects
      t.text :context
      t.references :place, foreign_key: true
      t.timestamps
    end
    add_index :revelations, :slug, unique: true
    add_index :revelations, :section_number, unique: true
    add_index :revelations, :received_on

    create_table :sources do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.string :author
      t.date :published_on
      t.string :url
      t.text :citation
      t.string :kind, null: false, default: "secondary"
      t.timestamps
    end
    add_index :sources, :slug, unique: true

    # --- Links between records ---

    create_table :event_participants do |t|
      t.references :event, null: false, foreign_key: true
      t.references :person, null: false, foreign_key: true
      t.string :role
      t.timestamps
    end
    add_index :event_participants, [ :event_id, :person_id ], unique: true

    create_table :revelation_people do |t|
      t.references :revelation, null: false, foreign_key: true
      t.references :person, null: false, foreign_key: true
      t.timestamps
    end
    add_index :revelation_people, [ :revelation_id, :person_id ], unique: true

    create_table :event_revelations do |t|
      t.references :event, null: false, foreign_key: true
      t.references :revelation, null: false, foreign_key: true
      t.timestamps
    end
    add_index :event_revelations, [ :event_id, :revelation_id ], unique: true

    create_table :citations do |t|
      t.references :source, null: false, foreign_key: true
      t.references :citable, polymorphic: true, null: false
      t.string :page
      t.text :note
      t.timestamps
    end

    create_table :images do |t|
      t.references :imageable, polymorphic: true, null: false
      t.string :file_name, null: false
      t.string :caption
      t.string :credit
      t.string :license
      t.integer :year
      t.boolean :is_modern, null: false, default: false
      t.timestamps
    end

    # --- Supporting records ---

    create_table :membership_estimates do |t|
      t.integer :year, null: false
      t.integer :members, null: false
      t.boolean :is_approximate, null: false, default: true
      t.text :note
      t.references :source, foreign_key: true
      t.timestamps
    end
    add_index :membership_estimates, :year, unique: true

    create_table :trivia_questions do |t|
      t.string :mode, null: false, default: "general"
      t.string :difficulty, null: false, default: "medium"
      t.text :prompt, null: false
      t.jsonb :choices, null: false, default: []
      t.string :answer, null: false
      t.text :explanation
      t.references :subject, polymorphic: true
      t.timestamps
    end
    add_index :trivia_questions, [ :mode, :difficulty ]
  end
end
