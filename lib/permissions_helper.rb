module PermissionsHelper
  def permission_fields(object_name, actions = [])
    actions = %w[index show new create edit update destroy] if actions.empty?
    actions.delete('create') if actions.include?('new')
    actions.delete('update') if actions.include?('edit')
    content_tag(:fieldset, :id => "#{object_name}_permissions") do
      content_tag(:legend, "Permissions") +
      actions.collect do |action|
        content_tag(:p) do
          label(object_name, "#{action}_permission", action.to_s.humanize) +
          tag('br') + "\n" +
          select(object_name, "#{action}_permission", [ ["allow", true], ["deny", false] ], {:include_blank => 'ignore'})
        end
      end.join("\n")
    end
  end
end
