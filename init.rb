ActiveRecord::Base.send :include, ActiveRecord::Acts::Permission
ActionController::Base.helper PermissionsHelper
