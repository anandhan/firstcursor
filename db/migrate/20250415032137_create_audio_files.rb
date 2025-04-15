class CreateAudioFiles < ActiveRecord::Migration[7.2]
  def change
    create_table :audio_files do |t|
      t.string :filename
      t.string :title
      t.string :artist
      t.string :album
      t.integer :year
      t.string :genre

      t.timestamps
    end
  end
end
