module PermissionsHelper
  def permission_fields(f)
    f.object.create_default_permissions!

    render 'acts_as_permission/permission_fields', :f => f
  end
end
