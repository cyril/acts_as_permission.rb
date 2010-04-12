require 'active_record/base'

module ActsAsPermission
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    attr_accessor :parental_resource_permission

    def acts_as_permission(resource = nil)
      attr_accessible :index_permission, :new_permission, :create_permission, :show_permission, :edit_permission, :update_permission, :destroy_permission
      before_save :complete_permissions_if_needed

      self.parental_resource_permission = resource

      class_eval <<-EOV
        include ActsAsPermission::InstanceMethods

        def self.could_have_permission_from_the_parent_resource?
          !self.parental_resource_permission.nil?
        end
      EOV
    end
  end

  module InstanceMethods
    def has_permission?(action)
      if self.respond_to?("#{action}_permission")
        return self.send("#{action}_permission") unless self.send("#{action}_permission").nil?
      end

      if self.class.could_have_permission_from_the_parent_resource?
        self.send(self.class.parental_resource_permission).has_permission?(action)
      else
        false
      end
    end

    private

    def complete_permissions_if_needed
      self.update_permission = self.edit_permission if self.respond_to?('edit_permission') && self.respond_to?('update_permission')
      self.create_permission = self.new_permission if self.respond_to?('new_permission') && self.respond_to?('create_permission')
      true
    end
  end
end

ActiveRecord::Base.class_eval { include ActsAsPermission }
ActionController::Base.helper PermissionsHelper
