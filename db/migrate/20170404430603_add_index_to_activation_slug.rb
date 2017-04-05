class AddIndexToActivationSlug < ActiveRecord::Migration
  def up
    add_index :activations, :slug
  end

  def down
    remove_index :activations, :slug
  end
end
