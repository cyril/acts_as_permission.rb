Acts as permission
==================

Acts as permission is a plugin for Ruby on Rails that allows to assign a list of
permissions on an object, according to the ACL concept, where each permission
can be extended to a subject.

More specifically, it can make possible to allow or to deny any action of the
controller of a protected resource.  These actions are called permittables.

A permittable action can be directly attached to a resource.  Examples of such
actions:

*   `show`,
*   `edit`,
*   `update`,
*   `destroy`.

Or it can be indirectly, through a parent resource.  Examples:

*   `index`,
*   `new`,
*   `create`.

Here is an example of query to a direct article's action:

    @article = Article.find(params[:id])
    @article.permission?("articles#destroy")          # => false

Same query, extended to a user:

    @article.permission?("articles#destroy", @bob)    # => nil
    @article.permission?("articles#destroy", @admin)  # => true

A query example on an indirect articles' action, through a category:

    @category = Category.find(params[:category_id])
    @category.permission?("articles#index")           # => true

Other examples, on unpermittable actions:

    @category.permission?("articles#read")            # => nil
    @category.permission?("silk_routes#index")        # => nil

The value of a permission depends on its context, which includes a route and an
optional extension to a permitted resource.

The `permission?(route, ext = nil)` query may return, depending on the context:

*   `true`, if the permission is allowed;
*   `false`, if the permission is denied;
*   `nil`, if the permission is indefinable (resulting of the unknown context).

Philosophy
----------

General library that does only one thing, without any feature.

Installation
------------

Include the gem in your `Gemfile`:

    gem 'acts_as_permission'

And run the +bundle+ command.  Or as a plugin:

    rails plugin install git://github.com/cyril/acts_as_permission.git

Then, generate files and apply the migration:

    rails generate permissions
    rake db:migrate

Getting started
---------------

### Configuring models

Permittable models have to be declared with `acts_as_permission`.  And they have
to be so with a default permission mask.  For example:

``` ruby
# app/models/article.rb
class Article < ActiveRecord::Base
  acts_as_permission({
    'articles#show'     => [true, {}],
    'articles#edit'     => [false, {
      permitted_id: 1,
      permitted_type: "User",
      value: true }],
    'articles#update'   => [false, {
      permitted_id: 1,
      permitted_type: "User",
      value: true }],
    'articles#destroy'  => [false, {
      permitted_id: 1,
      permitted_type: "User",
      value: true }],
    'comments#index'    => true,
    'comments#new'      => [true, [{
      permitted_id: 3,
      permitted_type: "User",
      value: false }]],
    'comments#create'   => [true, [{
      permitted_id: 3,
      permitted_type: "User",
      value: false }]]})

  belongs_to :user
  has_many :comments, dependent: :destroy
end

# app/models/comment.rb
class Comment < ActiveRecord::Base
  acts_as_permission([
    ["comments#show",    true],
    ["comments#edit",    [false, [
      {permitted_id: 1, permitted_type: "User", value: true},
      {permitted_id: 2, permitted_type: "User", value: true} ]]],
    ["comments#update",  [false, [
      {permitted_id: 1, permitted_type: "User", value: true},
      {permitted_id: 2, permitted_type: "User", value: true} ]]],
    ["comments#destroy", [false, {
      permitted_id: 1,
      permitted_type: "User",
      value: true }]]])

  belongs_to :article
  belongs_to :user
end
```

Optionally, some models (such as `User`, `Group`, `Role`) can also be declared
as permitted with `is_able_to_be_permitted`.  Example:

``` ruby
# app/models/user.rb
class User < ActiveRecord::Base
  is_able_to_be_permitted

  with_options(dependent: :destroy) do |opts|
    opts.has_many :articles
    opts.has_many :comments
  end
end
```

### Configuring controllers

Example of a fully protected comments controller:

``` ruby
class CommentsController < ApplicationController
  before_filter :check_permissions

  # GET /comments
  # GET /comments.xml
  def index
    @comments = current_resource.comments

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @comments }
    end
  end

  # GET /comments/1
  # GET /comments/1.xml
  def show
    @comment = current_resource

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @comment }
    end
  end

  # GET /comments/new
  # GET /comments/new.xml
  def new
    @comment = current_resource.comments.build

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @comment }
    end
  end

  # GET /comments/1/edit
  def edit
    @comment = current_resource
  end

  # POST /comments
  # POST /comments.xml
  def create
    @comment = current_resource.comments.build(params[:comment])

    respond_to do |format|
      if @comment.save
        format.html { redirect_to(@comment,
          :notice => 'Comment was successfully created.') }
        format.xml  { render :xml => @comment, :status => :created,
          :location => @comment }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @comment.errors,
          :status => :unprocessable_entity }
      end
    end
  end

  # PUT /comments/1
  # PUT /comments/1.xml
  def update
    @comment = current_resource

    respond_to do |format|
      if @comment.update_attributes(params[:comment])
        format.html { redirect_to(@comment,
          :notice => 'Comment was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @comment.errors,
          :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /comments/1
  # DELETE /comments/1.xml
  def destroy
    @comment = current_resource
    @comment.destroy

    respond_to do |format|
      format.html { redirect_to(comments_url) }
      format.xml  { head :ok }
    end
  end

  protected

  def check_permissions
    route = [ params[:controller],
              params[:action] ].join('#')

    unless (current_user &&
                         current_resource.permission?(route, current_user)) ||
                         current_resource.permission?(route)
      respond_to do |format|
        format.html { redirect_to(:back, :warning => '403 Forbidden',
          :status => :forbidden) }
        format.xml  { render :xml => '403 Forbidden', :status => :forbidden }
      end
    end
  end

  def current_resource
    @current_resource ||= if params[:id]
      Comment.find(params[:id])
    else
      Article.find(params[:article_id], :readonly => true)
    end
  end
end
```

### Configuring views

We can now perform some checks on related views from a comment instance, thanks
to the protected actions of its controller, in order to only display allowed
links:

``` ruby
if current_user && @comment.permission?("comments#edit", current_user) ||
                   @comment.permission?("comments#edit")
  link_to "Edit comment", edit_article_comment_path(@comment.article, @comment)
end
```

And also some indirect checks from the current article instance, like this one:

``` ruby
if current_user && @article.permission?("comments#index", current_user) ||
                   @article.permission?("comments#index")
  link_to "Comments", article_comments_path(@article)
end
```

Or this other one:

``` ruby
if current_user && @article.permission?("comments#new", current_user) ||
                   @article.permission?("comments#new")
  link_to "New comment", new_article_comment_path(@article)
end
```

#### Form helper

Object's permissions management is as simple as:

``` ruby
form_for @article do |f|
  permission_fields f
end
```

Copyright (c) 2009-2011 Cyril Wack, released under the MIT license
