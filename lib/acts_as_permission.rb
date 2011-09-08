module ActsAsPermission
  module Permittable
    def permission(route, ext = nil)
      ext = {
        :permitted_type => (ext.blank? ? nil : ext.class.name),
        :permitted_id   => (ext.blank? ? nil : ext.id) } unless ext.is_a? Hash

      context = {:route => route}.merge(ext)

      create_default_permission!(route, ext) unless permissions.exists?(context)

      permissions.first(:conditions => context)
    end

    def permission?(route, ext = nil)
      permission = permission(route, ext)
      permission.value? if permission.present?
    end

    def create_permission!(route, value, ext = nil)
      return unless self.class.permittable?(route)

      ext = {
        :permitted_type => (ext.blank? ? nil : ext.class.name),
        :permitted_id   => (ext.blank? ? nil : ext.id) } unless ext.is_a? Hash

      context = {:route => route}.merge(ext)
      parameters = context.merge(:value => value)

      permissions.create(parameters) unless permissions.exists?(context)
    end

    def create_default_permissions!
      permissions = self.class.permissions.map do |route, masks|
        masks.map do |mask|
          ext   = mask.dup
          value = ext.delete(:value)

          create_permission!(route, value, ext)
        end
      end

      permissions.flatten!
      permissions.compact
    end

    def has_permission?(action)
      ActiveSupport::Deprecation.warn 'has_permission?(action) is deprecated ' +
        'and may be removed from future releases, use permission?(route, ext ' +
        '= nil) instead.'

      permission? [self.class.name.tableize, action].join('#')
    end

    protected

    def create_default_permission!(route, ext = nil)
      return unless self.class.permittable?(route)

      ext = {
        :permitted_type => (ext.blank? ? nil : ext.class.name),
        :permitted_id   => (ext.blank? ? nil : ext.id) } unless ext.is_a? Hash

      masks = self.class.permissions[route.to_sym].select do |mask|
        mask[:permitted_id] == ext[:permitted_id] &&
          mask[:permitted_type] == ext[:permitted_type]
      end

      if (mask = masks.first).present?
        parameters = mask.merge({:route => route.to_s})
        permissions.create(parameters)
      end
    end
  end

  module Permitted
    def permitted?(object, route)
      object.permission?(route, self)
    end
  end
end

class ActiveRecord::Base
  def self.is_able_to_be_permitted
    has_many :permissions, :as => :permitted, :dependent => :destroy
    validates_associated :permissions

    include ActsAsPermission::Permitted
  end

  def self.acts_as_permission(acl)
    @acl = acl.to_a.inject({}) do |list, permission|
      route, masks = permission.to_a[0], permission.to_a[1]
      masks = [masks] unless masks.is_a?(Array)

      permission = {:value => masks.first}
      permission.freeze

      extensions = masks[1] || []
      extensions = [extensions] unless extensions.is_a?(Array)
      extensions.map! do |ext|
        ext ||= {}
        ext.freeze
      end

      permissions = extensions.unshift(permission)
      permissions.compact!
      permissions.uniq!
      permissions.freeze

      list.update({route.to_sym => permissions})
    end

    @acl.freeze

    has_many :permissions, :as => :permittable, :dependent => :destroy
    accepts_nested_attributes_for :permissions, :allow_destroy => true
    attr_accessible :permissions_attributes
    validates_associated :permissions

    class << self
      def permittable?(route)
        @acl.has_key?(route.to_sym)
      end

      def permissions
        @acl
      end
    end

    include ActsAsPermission::Permittable
  end
end
