# frozen_string_literal: true

class AddMonospaceEditorFontToUserOptions < ActiveRecord::Migration[8.0]
  def change
    add_column :user_options, :monospace_editor_font, :boolean, null: false, default: false
  end
end
