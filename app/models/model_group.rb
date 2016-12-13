class ModelGroup < ActiveRecord::Base
  include Search::Name
  audited

  attr_accessor :current_parent_id

  has_many :model_links, inverse_of: :model_group, dependent: :delete_all
  has_many :models, -> { uniq }, through: :model_links
  has_many :items, -> { uniq }, through: :models

  # has_many :all_model_links,
  #          :class_name => "ModelLink",
  #          :finder_sql => \
  #            proc { ModelLink.where(["model_group_id IN (?)",
  #                   descendant_ids]).to_sql }
  # has_many :all_models,
  #          -> { uniq },
  #          :class_name => "Model",
  #          :through => :all_model_links,
  #          :source => :model

  has_and_belongs_to_many :inventory_pools

  validates_presence_of :name

  accepts_nested_attributes_for :model_links, allow_destroy: true

  ##################################################

  # has_dag_links link_class_name: 'ModelGroupLink'

  has_many :parent_links,
    class_name: ::ModelGroupLink,
    foreign_key: :child_id

  has_many :child_links,
    class_name: ::ModelGroupLink,
    foreign_key: :parent_id

  has_and_belongs_to_many :children,
    join_table: :model_group_links, class_name: 'ModelGroup',
    foreign_key: :parent_id, association_foreign_key: :child_id

  has_and_belongs_to_many :parents,
    join_table: :model_group_links, class_name: 'ModelGroup',
    foreign_key: :child_id, association_foreign_key: :parent_id

  # p = FactoryGirl.create :model_group, name: 'Parent', type: 'ModelGroup'
  # c = FactoryGirl.create :model_group, name: 'Child', type: 'ModelGroup'
  # ModelGroupLink.create parent: p, child: c

  def self_and_descendant_ids
    descendant_ids + [id]
  end

  def descendant_ids(alread_found_descendants = Set.new([]))
    if alread_found_descendants.empty?
      children = Set.new(child_links.pluck(:child_id))
      if children.empty?
        children
      else
        descendant_ids children
      end
    else
      with_children_children = Set.new(alread_found_descendants + Set.new(alread_found_descendants.map{|did|self.class.find(did).child_links.pluck(:child_id)}.flatten))
      if with_children_children = alread_found_descendants
        with_children_children
      else
        descendant_ids with_children_children
      end
    end
  end

  def self_and_descendants
    self.class.where(id: self_and_descendant_ids.to_a)
  end

  # NOTE it's now chainable for scopes
  def all_models
    Model
      .select('DISTINCT models.*')
      .joins(:model_links)
      .where(model_links: { model_group_id: self_and_descendant_ids })
  end

  def image
    self.images.first || all_models.detect { |m| not m.image.blank? }.try(:image)
  end

  scope :roots, (lambda do
    joins('LEFT JOIN model_group_links AS mgl ' \
          'ON mgl.child_id = model_groups.id')
      .where('mgl.child_id IS NULL')
  end)

  # scope :accessible_roots, lambda do |user_id|
  # end

  ################################################
  # Edge Label

  def label(parent_id = nil)
    if parent_id
      l = links_as_descendant.find_by(ancestor_id: parent_id)
      return l.try(:label) || name
    end
    name
  end

  def set_parent_with_label(parent, label)
    ModelGroupLink.create_edge(parent, self)
    l = links_as_child.find_by(ancestor_id: parent.id)
    l.update_attributes(label: label) if l
  end

  ################################################

  def to_s
    name
  end

  # compares two objects in order to sort them
  def <=>(other)
    self.name.downcase <=> other.name.downcase
  end

end
