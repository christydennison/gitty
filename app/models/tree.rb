# Tree (directory) in a git repository hosted on this server.
class Tree < ActiveRecord::Base
  include GitObjectModel
  
  # The repository that this tree is a part of.
  belongs_to :repository, :inverse_of => :trees
  validates :repository, :presence => true
  
  # The git object id (sha of the object's data).
  validates :gitid, :length => 1..64, :presence => true,
                    :uniqueness => { :scope => :repository_id }  

  # The tree's contents.
  has_many :entries, :class_name => 'TreeEntry', :inverse_of => :tree
  
  # Tree model for an on-disk tree (directory).
  #
  # Args:
  #   git_tree:: a Grit::Tree object
  #   repository:: the Repository that this tree will belong to
  #
  # Returns an unsaved Tree model. It needs to be saved before child links to it
  # are created by calling TreeEntry#from_git_tree.
  def self.from_git_tree(git_tree, repository)
    self.new :repository => repository, :gitid => git_tree.id
  end
  
  # Use git SHAs instead of IDs.
  def to_param
    gitid
  end
  
  # The tree or blob obtained by walking through a path in the commit's tree.
  def walk_path(path)
    object = self
    path.split('/').each do |segment|
      next if segment.empty?
      entry = object.entries.where(:name => segment).first
      return nil unless entry
      object = entry.child
    end
    object
  end
end
