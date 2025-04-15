class AddCoverArtAndComposerToAudioFiles < ActiveRecord::Migration[7.2]
  def change
    add_column :audio_files, :cover_art, :string
    add_column :audio_files, :composer, :string
  end
end
