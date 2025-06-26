# frozen_string_literal: true

class AddFlexibleToPolls < ActiveRecord::Migration[7.0]
  def change
    add_column :polls, :flexible, :boolean, null: false, default: false
  end
end
