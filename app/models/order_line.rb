class OrderLine < DocumentLine

  belongs_to :order
  alias :document :order
  belongs_to :inventory_pool
  belongs_to :model
  has_one :user, :through => :order
  has_many :groups, :through => :user

  validates_presence_of :order
  validate do
    # TODO ?? model.inventory_pools.include?(order.inventory_pool)
    errors.add(:base, _("Inconsistent Inventory Pool")) if order.status_const != 1 and inventory_pool_id != order.inventory_pool_id
  end

  before_save do
    # OPTIMIZE suggest best possible inventory pool according to the other order_lines
    # TODO 08** in case of backend add_line, make sure is assigned to current_inventory_pool
    if self.inventory_pool.nil?
      inventory_pools = model.inventory_pools & order.user.inventory_pools # TODO 08** also scope to the selected frontend inventory_pools ?? 
      inventory_pools.each do |ip|
         if ip.items.where(:model_id => model.id).count >= quantity
           self.inventory_pool = ip
           break
         end
      end
    end
  end

  scope :submitted,   joins(:order).where(["orders.status_const = ?", Order::SUBMITTED])
  scope :unsubmitted, joins(:order).where(["orders.status_const = ?", Order::UNSUBMITTED])
  scope :running,     lambda { |date| where(["end_date >= ?", date]) }
  scope :by_user,     lambda { |user| joins(:order).where(:orders => {:user_id => user}) }

###############################################

  def self.grouped_by_inventory_pool(order_lines)
    order_lines.sort {|a,b| a.created_at <=> b.created_at }.group_by {|order_line| order_line.inventory_pool }
  end

###############################################

  def is_late?(current_date = Date.today)
    false #TODO 27 Not necessary anymore
  end

  def item
    nil
  end
  alias :item_id :item 
  
  def type
    self.class.to_s.underscore
  end
    
end

