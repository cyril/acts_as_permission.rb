class ActsAsPermissionGenerator < Rails::Generator::NamedBase
  def initialize(runtime_args, runtime_options = {})
    super
    @args = actions if @args.empty?
  end

  def manifest
    record do |m|
      m.migration_template 'migration:migration.rb', "db/migrate", {:assigns => permissions_local_assigns, :migration_file_name => "add_permissions_fields_to_#{plural_name}"}
    end
  end

  def class_name
    name.camelize
  end

  def plural_name
    custom_name = class_name.underscore.downcase
    custom_name = custom_name.pluralize if ActiveRecord::Base.pluralize_table_names
    custom_name
  end

  private

  def actions
    %w[index show new create edit update destroy]
  end

  def permissions_local_assigns
    returning(assigns = {}) do
      assigns[:migration_action] = "add"
      assigns[:class_name] = "add_permissions_fields_to_#{plural_name}"
      assigns[:table_name] = plural_name
      assigns[:attributes] = []
      @args.each do |action|
        assigns[:attributes] << Rails::Generator::GeneratedAttribute.new("#{action}_permission", "boolean")
      end
    end
  end
end
