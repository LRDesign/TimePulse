# == Schema Information
#
# Table name: users
#
#  id                  :integer(4)      not null, primary key
#  login               :string(255)     not null
#  email               :string(255)     not null
#  current_project_id  :integer(4)
#  name                :string(255)     not null
#  crypted_password    :string(255)     not null
#  password_salt       :string(255)     not null
#  persistence_token   :string(255)     not null
#  single_access_token :string(255)     not null
#  perishable_token    :string(255)     not null
#  login_count         :integer(4)      default(0), not null
#  failed_login_count  :integer(4)      default(0), not null
#  last_request_at     :datetime
#  current_login_at    :datetime
#  last_login_at       :datetime
#  current_login_ip    :string(255)
#  last_login_ip       :string(255)
#  created_at          :datetime
#  updated_at          :datetime
#

class User < ActiveRecord::Base

  devise :database_authenticatable, :registerable,
       :recoverable, :rememberable, :trackable, :validatable, :confirmable

  belongs_to :current_project, :class_name => "Project"
  has_many :work_units
  has_many :bills
  has_many :activities
  has_many :rates_users
  has_many :rates, :through => :rates_users
  has_one  :user_preferences

  validates_presence_of :name, :email

  scope :inactive, lambda { where(inactive: true )  }

  scope :active,   lambda { where(inactive: false)  }

  def reset_current_work_unit
    @cwu = nil
  end

  def current_work_unit
    @cwu ||= work_units.in_progress.first
  end

  def clocked_in?
    reset_current_work_unit
    !current_work_unit.nil?
  end

  def recent_projects
    @wu_list = (WorkUnit.user_work_units(self).most_recent(100))
    @pid_list = @wu_list.collect{ |w| w.project_id }.uniq[0..(self.user_preferences.recent_projects_count-1)]
    Project.find(@pid_list).sort_by{ |proj| @pid_list.index(proj.id) }
  end

  def recent_work_units
    work_units.completed.recent.includes(:project => :client)
  end

  def recent_commits
    activities.git_commits.recent.includes(:project => :client)
  end

  def recent_pivotal_updates
    activities.pivotal_updates.recent.includes(:project => :client)
  end

  def time_on_project(project)
    work_units_for(project).sum(:hours)
  end

  def unbilled_time_on_project(project)
    work_units_for(project).unbilled.sum(:hours)
  end

  def unbillable_time_on_project(project)
    work_units_for(project).unbillable.sum(:hours)
  end

  def completed_work_units_for(project)
    work_units_for(project).completed
  end

  def git_commits_for(project)
    source = project.github_url_source
    source ||= project
    activity_for(source).git_commits
  end

  def pivotal_updates_for(project)
    source = project.pivotal_id_source
    source ||= project
    activity_for(source).pivotal_updates
  end

  def current_project_hours_report
    @cphr ||= hours_report_on(current_project)
  end

  def hours_report_on(project)
    HoursReport.new(project, self)
  end

  def old_admin?
    #groups.include?(Group.admin_group)
  end

  def admin?
    admin
  end

  def activity_for(project)
    ProjectActivityQuery.new(activities).find_for_project(project)
  end

  def work_units_for(project)
    ProjectWorkQuery.new(work_units).find_for_project(project)
  end

  def rate_for(project)
    project = project.parent unless project.is_base_project?
    (project.rates & rates).last
  end

  def active_for_authentication?
    super && !self.inactive?
  end

  def self.find_first_by_auth_conditions(warden_conditions)
    conditions = warden_conditions.dup
    if login = conditions.delete(:login)
      where(conditions).where(["lower(login) = :value OR lower(email) = :value",
                               { :value => login.downcase}]).first
    else
      where(conditions).first
    end
	end

	def total_hours(time_period)
		if time_period == 'six_weeks_ago'
			work_units.where(:start_time => Time.now.beginning_of_week - 1.second - 41.days..Time.now.beginning_of_week - 1.second - 35.days).sum(:hours).to_s.to_f
		elsif time_period == 'five_weeks_ago'
			work_units.where(:start_time => Time.now.beginning_of_week - 1.second - 34.days..Time.now.beginning_of_week - 1.second - 28.days).sum(:hours).to_s.to_f
		elsif time_period == 'four_weeks_ago'
			work_units.where(:start_time => Time.now.beginning_of_week - 1.second - 27.days..Time.now.beginning_of_week - 1.second - 21.days).sum(:hours).to_s.to_f
		elsif time_period == 'three_weeks_ago'
			work_units.where(:start_time => Time.now.beginning_of_week - 1.second - 20.days..Time.now.beginning_of_week - 1.second - 14.days).sum(:hours).to_s.to_f
		elsif time_period == 'two_weeks_ago'
			work_units.where(:start_time => Time.now.beginning_of_week - 1.second - 13.days..Time.now.beginning_of_week - 1.second - 7.days).sum(:hours).to_s.to_f
		elsif time_period == 'one_week_ago'
			work_units.where(:start_time => Time.now.beginning_of_week - 1.second - 6.days..Time.now.beginning_of_week - 1.second).sum(:hours).to_s.to_f
		end
	end

	def billable_hours(time_period)
		if time_period == 'six_weeks_ago'
			work_units.where(:start_time => Time.now.beginning_of_week - 1.second - 41.days..Time.now.beginning_of_week - 1.second - 35.days).billable.sum(:hours).to_s.to_f
		elsif time_period == 'five_weeks_ago'
			work_units.where(:start_time => Time.now.beginning_of_week - 1.second - 34.days..Time.now.beginning_of_week - 1.second - 28.days).billable.sum(:hours).to_s.to_f
		elsif time_period == 'four_weeks_ago'
			work_units.where(:start_time => Time.now.beginning_of_week - 1.second - 27.days..Time.now.beginning_of_week - 1.second - 21.days).billable.sum(:hours).to_s.to_f
		elsif time_period == 'three_weeks_ago'
			work_units.where(:start_time => Time.now.beginning_of_week - 1.second - 20.days..Time.now.beginning_of_week - 1.second - 14.days).billable.sum(:hours).to_s.to_f
		elsif time_period == 'two_weeks_ago'
			work_units.where(:start_time => Time.now.beginning_of_week - 1.second - 13.days..Time.now.beginning_of_week - 1.second - 7.days).billable.sum(:hours).to_s.to_f
		elsif time_period == 'one_week_ago'
			work_units.where(:start_time => Time.now.beginning_of_week - 1.second - 6.days..Time.now.beginning_of_week - 1.second).billable.sum(:hours).to_s.to_f
		end
	end

	def unbillable_hours(time_period)
		if time_period == 'six_weeks_ago'
			work_units.where(:start_time => Time.now.beginning_of_week - 1.second - 41.days..Time.now.beginning_of_week - 1.second - 35.days).unbillable.sum(:hours).to_s.to_f
		elsif time_period == 'five_weeks_ago'
			work_units.where(:start_time => Time.now.beginning_of_week - 1.second - 34.days..Time.now.beginning_of_week - 1.second - 28.days).unbillable.sum(:hours).to_s.to_f
		elsif time_period == 'four_weeks_ago'
			work_units.where(:start_time => Time.now.beginning_of_week - 1.second - 27.days..Time.now.beginning_of_week - 1.second - 21.days).unbillable.sum(:hours).to_s.to_f
		elsif time_period == 'three_weeks_ago'
			work_units.where(:start_time => Time.now.beginning_of_week - 1.second - 20.days..Time.now.beginning_of_week - 1.second - 14.days).unbillable.sum(:hours).to_s.to_f
		elsif time_period == 'two_weeks_ago'
			work_units.where(:start_time => Time.now.beginning_of_week - 1.second - 13.days..Time.now.beginning_of_week - 1.second - 7.days).unbillable.sum(:hours).to_s.to_f
		elsif time_period == 'one_week_ago'
			work_units.where(:start_time => Time.now.beginning_of_week - 1.second - 6.days..Time.now.beginning_of_week - 1.second).unbillable.sum(:hours).to_s.to_f
		end
	end
end
