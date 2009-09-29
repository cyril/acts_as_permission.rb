Description:
    Alter the structure model in order to attache an access control list (ACL)
    to its resources.

Usage:
    Pass the name of the model, and an optional list of controller actions.

    If no controller actions is specified, those following will be generated:
    index, show, new, create, edit, update and destroy.

Examples:
    script/generate acts_as_permission Article

        Will alter the Article model table by adding a field for each seven
        default actions (index, show, create, new, edit, update, and destroy).

    script/generate acts_as_permission Category index new create

        Will alter categories table with index, new and create action
        permission fields.
