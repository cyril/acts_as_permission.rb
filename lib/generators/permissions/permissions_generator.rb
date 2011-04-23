require 'rails/generators/migration'

class PermissionsGenerator < Rails::Generators::Base
  include Rails::Generators::Migration

  source_root File.expand_path('../templates', __FILE__)

  def self.next_migration_number(path)
    Time.now.utc.strftime("%Y%m%d%H%M%S")
  end

  def create_model_file
    template 'permission.rb', 'app/models/permission.rb'
    template 'permissions_helper.rb', 'app/helpers/permissions_helper.rb'
    migration_template 'create_permissions.rb', 'db/migrate/create_permissions.rb'
  end
end
