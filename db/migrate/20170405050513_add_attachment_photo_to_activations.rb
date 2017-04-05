class AddAttachmentPhotoToActivations < ActiveRecord::Migration
  def self.up
    change_table :activations do |t|
      t.attachment :photo
    end
  end

  def self.down
    drop_attached_file :activations, :photo
  end
end
