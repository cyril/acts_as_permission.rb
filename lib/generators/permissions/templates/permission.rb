class Permission < ActiveRecord::Base
  attr_accessible :route, :value, :permitted_id, :permitted_type
  attr_readonly :route, :permitted_id, :permitted_type

  with_options :polymorphic => true do |opts|
    opts.belongs_to :permittable
    opts.belongs_to :permitted
  end

  validates_format_of :route, :with => /^[^#]+#[^#]+$/
  validates_inclusion_of :value, :in => [true, false]
  validates_presence_of :permittable, :route

  validates_uniqueness_of :route, :on => :create, :scope => [
    :permittable_type, :permittable_id,
    :permitted_type, :permitted_id ]

  validate :permittable_route, :on => :create

  protected

  def permittable_route
    unless permittable.class.permittable?(route)
      errors.add :route, :is_not_included_in_the_list
    end
  end
end
