class AddVisibleInSelectsInPackageType < ActiveRecord::Migration
  def up
    add_column :package_types, :visible_in_selects, :boolean, default: false

    PackageType.reset_column_information
    PackageType.update_all(visible_in_selects: true)
  end

  def down
    remove_column :package_types, :visible_in_selects
  end
end
