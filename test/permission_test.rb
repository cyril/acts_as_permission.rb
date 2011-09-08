require 'test_helper'

ActiveRecord::Base.establish_connection(
  :adapter => 'sqlite3', :database => ':memory:')

def setup_db
  ActiveRecord::Schema.define(:version => 1) do
    create_table :users do |t|
      t.string :login
    end

    create_table :blogs do |t|
      t.references :user, :null => false
      t.string :title
    end

    create_table :categories do |t|
      t.references :blog, :null => false
      t.string :title
    end

    create_table :articles do |t|
      t.references :publishable, :polymorphic => true, :null => false
      t.references :user
      t.string :title
      t.text :content
    end

    create_table :comments do |t|
      t.references :article, :null => false
      t.references :user
      t.text :content
    end

    create_table :permissions do |t|
      t.string :route, :null => false
      t.boolean :value, :null => false
      t.references :permittable, :polymorphic => true, :null => false
      t.references :permitted, :polymorphic => true
      t.timestamps
    end
  end
end

def teardown_db
  ActiveRecord::Base.connection.tables.each do |table|
    ActiveRecord::Base.connection.drop_table(table)
  end
end

class User < ActiveRecord::Base
  is_able_to_be_permitted

  has_one :blog, :dependent => :destroy
  has_many :articles, :dependent => :destroy
  has_many :comments, :dependent => :destroy
end

class Blog < ActiveRecord::Base
  acts_as_permission({
    :"articles#index"    => true,
    :"articles#new"      => [false, {
      :permitted_id => 1, :permitted_type => "User", :value => true}],
    :"articles#create"   => [false, {
      :permitted_id => 1, :permitted_type => "User", :value => true}],
    :"categories#index"  => true,
    :"categories#new"    => [false, {
      :permitted_id => 1, :permitted_type => "User", :value => true}],
    :"categories#create" => [false, {
      :permitted_id => 1, :permitted_type => "User", :value => true}],
    :"blogs#show"        => true,
    :"blogs#edit"        => [false, {
      :permitted_id => 1, :permitted_type => "User", :value => true}],
    :"blogs#update"      => [false, [
      {:permitted_id => 1, :permitted_type => "User", :value => true}]],
    :"blogs#destroy"     => [false, {
      :permitted_id => 1, :permitted_type => "User", :value => true}]})

  belongs_to :user
  has_many :articles, :as => :publishable, :dependent => :destroy
  has_many :categories, :dependent => :destroy
end

class Category < ActiveRecord::Base
  acts_as_permission({
    'articles#index'      => true,
    'articles#new'        => [false, {
      :permitted_id => 1, :permitted_type => "User", :value => true}],
    'articles#create'     => [false, {
      :permitted_id => 1, :permitted_type => "User", :value => true}],
    'categories#show'     => true,
    'categories#edit'     => [false, {
      :permitted_id => 1, :permitted_type => "User", :value => true}],
    'categories#update'   => [false, {
      :permitted_id => 1, :permitted_type => "User", :value => true}],
    'categories#destroy'  => [false, {
      :permitted_id => 1, :permitted_type => "User", :value => true}]})

  belongs_to :blog
  has_many :articles, :as => :publishable, :dependent => :destroy
end

class Article < ActiveRecord::Base
  acts_as_permission({
    'articles#show'     => [true, {}],
    'articles#edit'     => [false, {
      :permitted_id => 1, :permitted_type => "User", :value => true}],
    'articles#update'   => [false, {
      :permitted_id => 1, :permitted_type => "User", :value => true}],
    'articles#destroy'  => [false, {
      :permitted_id => 1, :permitted_type => "User", :value => true}],
    'comments#index'    => true,
    'comments#new'      => [true, [
      {:permitted_id => 3, :permitted_type => "User", :value => false}]],
    'comments#create'   => [true, [
      {:permitted_id => 3, :permitted_type => "User", :value => false}]]})

  belongs_to :publishable, :polymorphic => true
  belongs_to :user
  has_many :comments, :dependent => :destroy
end

class Comment < ActiveRecord::Base
  acts_as_permission([
    ["comments#show",     true],
    ["comments#edit",     [false, [
      {:permitted_id => 1, :permitted_type => "User", :value => true},
      {:permitted_id => 2, :permitted_type => "User", :value => true}]]],
    ["comments#update",   [false, [
      {:permitted_id => 1, :permitted_type => "User", :value => true},
      {:permitted_id => 2, :permitted_type => "User", :value => true}]]],
    ["comments#destroy",  [false, {
      :permitted_id => 1, :permitted_type => "User", :value => true}]]])

  belongs_to :article
  belongs_to :user
end

class Permission < ActiveRecord::Base
  attr_accessible :route, :value, :permitted_id, :permitted_type
  attr_readonly :route, :permitted_id, :permitted_type

  belongs_to :permittable, :polymorphic => true
  belongs_to :permitted, :polymorphic => true

  validates_format_of :route, :with => /^[^#]+#[^#]+$/
  validates_inclusion_of :value, :in => [true, false]
  validates_presence_of :permittable, :route

  validates_uniqueness_of :route, :on => :create, :scope => [
    :permittable_type, :permittable_id,
    :permitted_type, :permitted_id ]
end

class PermissionTest < MiniTest::Unit::TestCase
  def setup
    setup_db

    @admin    = User.create! :login => 'admin'
    @bob      = User.create! :login => 'bob'
    @spammer  = User.create! :login => 'spammer'

    @blog = @admin.create_blog :title => 'my_blog'
    @category = @blog.categories.create! :title => 'main'
    @article = @category.articles.create! :title => 'hello, world',
      :user => @admin
    @comment0 = @article.comments.create! :content => 'foobar',
      :user => @bob
    @comment1 = @article.comments.create! :content => 'spam spam spam',
      :user => @spammer
  end

  def teardown
    teardown_db
  end

  def test_permissibilities
    refute Blog.permittable?("silk_routes#index")
    refute Blog.permittable?("blogs#index")
    assert Blog.permittable?('blogs#show')
    assert Blog.permittable?(:"articles#index")
    assert Category.permittable?("categories#show")
    assert Article.permittable?("articles#show")
  end

  def test_permissions
    assert @blog.permissions.empty?
    refute @blog.permission?("blogs#edit")
    refute @blog.permission?("blogs#destroy")
    refute @blog.permissions.empty?
    assert @blog.permission?("blogs#show")
    assert @blog.has_permission?("show")
    assert_nil @blog.permission?("blogs#show", @spammer)
    assert @blog.permission?(:"categories#create", @admin)
    refute @blog.permission?("articles#new")
    assert_nil @blog.permission?("silk_routes#index")
    assert_equal 5, @blog.permissions.count
    @blog.permissions.delete_all
    assert_empty @blog.permissions
    refute_empty @blog.create_default_permissions!
    assert_equal @blog.permissions.length, @blog.permissions.count
    refute_empty @blog.permissions
    @blog.permissions.delete_all
    assert_empty @blog.permissions
    assert_empty @blog.permissions
    refute_nil @blog.create_permission!("categories#create", false, @admin)
    assert_equal 1, @blog.permissions.count
    refute @blog.permission?(:"categories#create", @admin)
    assert_equal 1, @blog.permissions.count
    @blog.permissions.delete_all
    assert_empty @blog.permissions
    assert @blog.permission("categories#create", @admin).
      update_attribute(:value, false)
    assert_equal 1, @blog.permissions.count
    refute @blog.permission?(:"categories#create", @admin)
    assert_equal 1, @blog.permissions.count
    @blog.permissions.delete_all
    assert_empty @blog.permissions
    refute_nil @blog.create_permission!("categories#create", true, @admin)
    assert @blog.permission?(:"categories#create", @admin)
    @blog.permissions.delete_all
    assert_empty @blog.permissions
    refute_nil @blog.create_permission!("categories#create", true, @admin)
    assert @blog.permission?(:"categories#create", @admin)
    @blog.permissions.delete_all
    assert_empty @blog.permissions
    refute_nil @blog.create_permission!("categories#create", true, @bob)
    refute Blog.first.permissions.empty?
    assert_equal @blog.permissions.length, @blog.permissions.count
    assert @blog.permission?(:"categories#create", @bob)
    assert_nil @blog.create_permission!("categories#create", true, @bob)
    assert @blog.permission?(:"categories#create", @bob)

    assert @category.permissions.empty?
    assert_nil @category.permission?(:yay)
    assert @category.permissions.empty?
    assert @category.permission?("articles#index")
    refute @category.permissions.empty?
    assert_nil @category.permission?("blogs#show")
    assert @category.permission?("categories#show")
    assert @category.permission?("categories#show")
    assert_nil @category.permission?(:"categories#create", @admin)
    assert_nil @category.permission?("categories#new", @bob)
    assert_nil @category.permission?("categories#create")
    refute @category.permission?("articles#create")
    assert_equal 3, @category.permissions.count
    refute_nil @category.create_permission!("articles#new", true, @bob)
    assert_equal 4, @category.permissions.count
    assert @category.permission?("articles#new", @bob)
    assert_equal 4, @category.permissions.count
    refute_nil @category.create_permission!("articles#create", true, @bob)
    assert_equal 5, @category.permissions.count
    assert @category.permission?("articles#create", @bob)
    assert_nil @category.permission?("articles#show", @bob)
    assert_equal 5, @category.permissions.count
    @category.permissions.delete_all
    assert_empty @category.permissions
    assert_nil @category.permission?("articles#create", @bob)
    refute_nil @category.create_permission!("articles#create", true, @bob)
    assert @category.permission?("articles#create", @bob)
    refute_nil @category.create_permission!("articles#index", false)
    assert_equal 2, @category.permissions.count
    refute_empty @category.create_default_permissions!
    assert @category.permission?("articles#create", @bob)
    refute @category.permission?("articles#index")
    assert @category.permission("articles#index").update_attribute(:value, true)
    assert @category.permission?("articles#index")

    assert @admin.permitted?(@category, "categories#edit")

    assert @article.permission?(:"articles#destroy", @admin)
    assert_equal 1, @article.permissions.count
    assert @article.permission?("articles#destroy", @admin)
    assert @admin.permitted?(@article, "articles#destroy")
    assert_equal 1, @article.permissions.count
    assert_nil @article.permission?("articles#show", @admin)
    assert @article.permission?('articles#show')
    assert_equal 2, @article.permissions.count
    assert @article.permission?('comments#new')
    assert_nil @article.permission?('comments#new', @admin)
    assert_nil @article.permission?('comments#new', @bob)
    refute @article.permission?('comments#new', @spammer)
    refute @article.permission?('comments#create', @spammer)
    assert_equal 5, @article.permissions.count
    @article.permissions.delete_all
    assert_empty @article.permissions
    assert_equal 0, @article.permissions.count
    assert @article.permission?('comments#new')
    assert_equal @article.permissions.count, @article.permissions.length
    assert_equal 1, @article.permissions.count
    refute_empty @article.create_default_permissions!
    assert_equal @article.permissions.count, @article.permissions.length
    refute @article.permission?(:"articles#destroy", @spammer)

    refute_empty @article.permissions_attributes = [{
      :route => "articles#destroy", :value => true,
      :permitted_id => @spammer.id, :permitted_type => @spammer.class.name }]
    assert @article.save

    # Should work, knowed bug:
    #   https://rails.lighthouseapp.com/projects/8994/tickets/2160
    #assert @article.update_attributes({:permissions_attributes => [{
    #  :route => "articles#destroy", :value => true,
    #  :permitted_id => @spammer.id, :permitted_type => @spammer.class.name }]})

    assert @article.permission?(:"articles#destroy", @spammer)

    assert_nil @spammer.permitted?(@article, "categories#show")
    assert_nil @spammer.permitted?(@article, "categories#secret")

    refute @spammer.permitted?(@article, "comments#new")
    assert_nil @bob.permitted?(@article, "comments#new")

    assert_nil @comment0.permission?(:"comments#show", @admin)
    assert_equal 0, @comment0.permissions.count
    assert @comment0.permission?(:"comments#show")
    assert_equal 1, @comment0.permissions.count
    assert_nil @comment0.permission?(:"comments#destroy_all")
    assert_equal 1, @comment0.permissions.count
    refute @comment0.permission?(:"comments#destroy")
    assert_equal 2, @comment0.permissions.count
    assert @comment0.permission?(:"comments#destroy", @admin)
    assert_equal 3, @comment0.permissions.count
    assert_empty @comment1.permissions
    refute_nil @comment1.permissions.create!({
      :route => 'comments#show', :value => false })
    assert_equal 1, @comment1.permissions.count
    refute @comment1.permission?(:"comments#show")
    assert_equal 1, @comment1.permissions.count
    @comment1.permissions.delete_all
    assert_empty @comment1.permissions
    assert @comment1.permission?(:"comments#show")
    assert_equal 1, @comment1.permissions.count
    refute_nil @comment1.permission("comments#show").
      update_attribute(:value, false)
    refute @comment1.permission?(:"comments#show")
    assert_nil @comment1.permission("comments#show", @bob)
    assert_nil @comment1.permission?(:"comments#show", @bob)
    assert_equal 1, @comment1.permissions.count
  end
end
