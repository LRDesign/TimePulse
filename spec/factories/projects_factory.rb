# == Schema Information
#
# Table name: projects
#
#  id          :integer(4)      not null, primary key
#  parent_id   :integer(4)
#  lft         :integer(4)
#  rgt         :integer(4)
#  client_id   :integer(4)
#  name        :string(255)
#  account     :string(255)
#  description :text
#  created_at  :datetime
#  updated_at  :datetime
#

Factory.define :project  do |c|
  c.name "Clientactics Project"
  c.association :client
end

Factory.define :task, :parent => :project do |c|
  c.name "Clientactics Task"  
  c.clockable true  
  c.parent { |parent| parent.association(:project) }
end