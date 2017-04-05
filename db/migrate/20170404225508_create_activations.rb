class CreateActivations < ActiveRecord::Migration
  def change
    create_table :activations do |t|
      t.integer :category_id
      t.string :name
      t.string :slug
      t.string :sponsor
      t.string :blurb
      t.string :description
      t.string :url
      t.integer :spots_available
      t.string :time_range
      t.date :happening_on
      t.string :where
      t.boolean :is_public
      t.timestamps
    end
  end
end
