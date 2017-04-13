class ChangeActivationDescriptionTypeToText < ActiveRecord::Migration
  def change
    change_table :activations do |t|
      t.change :description, :text
    end
  end
end
