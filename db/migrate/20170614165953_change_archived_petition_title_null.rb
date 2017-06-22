class ChangeArchivedPetitionTitleNull < ActiveRecord::Migration
  def up
    change_column_null(:archived_petitions, :title, true)
  end

  def down
    change_column_null(:archived_petitions, :title, false)
  end
end
