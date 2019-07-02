# ## Schema Information
#
# Table name: `expenses`
#
# ### Columns
#
# Name                     | Type               | Attributes
# ------------------------ | ------------------ | ---------------------------
# **`id`**                 | `bigint(8)`        | `not null, primary key`
# **`amount`**             | `integer`          |
# **`both_flg`**           | `boolean`          | `default(FALSE)`
# **`date`**               | `date`             |
# **`memo`**               | `string`           |
# **`mypay`**              | `integer`          |
# **`partnerpay`**         | `integer`          |
# **`percent`**            | `integer`          | `default("pay_all"), not null`
# **`created_at`**         | `datetime`         | `not null`
# **`updated_at`**         | `datetime`         | `not null`
# **`category_id`**        | `integer`          |
# **`repeat_expense_id`**  | `bigint(8)`        |
# **`user_id`**            | `integer`          |
#
# ### Indexes
#
# * `index_expenses_on_repeat_expense_id`:
#     * **`repeat_expense_id`**
#
# ### Foreign Keys
#
# * `fk_rails_...`:
#     * **`repeat_expense_id => repeat_expenses.id`**
#

class Expense < ApplicationRecord
  include BalanceHelper
  include PercentCalculator

  # todo: これはテーブルを作ってユーザーが自由に変更できるようにする。
  enum percent: { manual_amount: -1, pay_all: 0, pay_half: 1, pay_one_third: 2, pay_two_thirds: 3, pay_nothing: 4 }

  attr_accessor :is_new, :is_destroyed, :differences
  alias_method :is_new?, :is_new
  alias_method :is_destroyed?, :is_destroyed
  alias_attribute :is_for_both?, :both_flg

  belongs_to :user
  belongs_to :category

  before_validation :set_mypay_and_partnerpay

  validates :amount, :date, :percent, presence: true
  validates_length_of :amount, :mypay, :partnerpay, maximum: 10
  validates_length_of :memo, maximum: 100
  validate :calculate_amount

  end_of_this_month = Date.today.end_of_month
  beginning_of_this_month = Date.today.beginning_of_month
  end_of_last_month = Date.today.months_ago(1).end_of_month
  beginning_of_last_month = Date.today.months_ago(1).beginning_of_month
  scope :this_month, -> {where('date >= ? AND date <= ?', beginning_of_this_month, end_of_this_month)}
  scope :last_month, -> {where('date >= ? AND date <= ?', beginning_of_last_month, end_of_last_month)}
  scope :until_last_month, -> {where('date <= ?', end_of_last_month)}
  # 引数はString。 例: "2019-01"
  scope :one_month, -> (period) {where('date >= ? AND date <= ?', period.to_beginning_of_month, period.to_end_of_month)}
  scope :except_repeat_ones, -> {where.not()}
  scope :category, -> (category_id){unscope(:order).where(category_id: category_id).order(date: :desc, created_at: :desc)}
  scope :both_f, -> {where(both_flg: false)}
  scope :both_t, -> {where(both_flg: true)}
  scope :newer, -> {order(date: :desc, created_at: :desc)}

  after_initialize { self.is_new = true unless self.id }
  before_save :set_differences
  before_destroy { self.is_destroyed = true }
  after_commit { go_calculate_balance(self) }

  # 金額に関するカラムを配列で返す。
  def self.money_attributes
    %w(amount mypay partnerpay)
  end

  # @param [User] user
  # @param [String] period "2019-02"
  # @return [Expense]
  def self.all_for_one_month(user, period)
    partner = user.partner
    self.includes(:user, :category).references(:users, :categories).where(users: {id: [user, partner]}).one_month(period).order(date: :desc, created_at: :desc)
  end

  # @note 該当月と引数のカテゴリの出費でユーザーの全ての出費とパートナーの二人の出費を取得
  # @param [User] user
  # @param [Category] category
  # @param [String] period "2019-02"
  # @return [Expense]
  def self.specified_category_for_one_month(user, category, period)
    partner = user.partner
    self.includes(:user, :category).references(:users, :categories).where(categories: {id: category}).one_month(period).where("users.id = ? OR (users.id = ? AND both_flg = ?)", user.id, partner.id, true).order(date: :desc, created_at: :desc)
  end

  # ユーザーと該当月からその月の支出合計額を算出
  # @param user: Userクラス, month: Stringクラス "2019-01"
  # @return Integer 支出合計額
  def self.one_month_total_expenditures(user, period)
    # 自分の一人の出費の支払い額(amount)の合計額 + 自分の二人の出費の自分の支払い分(mypay)の合計額 + パートナーの二人の出費のパートナーの支払い分(partner)の合計額
    user_expenses = user.expenses.one_month(period)
    user_expenses.both_f.sum(:amount) + user_expenses.both_t.sum(:mypay) + user.partner.expenses.one_month(period).both_t.sum(:partnerpay)
  end

  def self.necessary_attributes_from_repeat_exepnses
    %w(amount memo category_id user_id both_flg mypay partnerpay percent)
  end

  def is_own_expense?(user, category=self.category)
    !is_for_both? && self.user == user && self.category == category
  end

  def is_both_expense_paid_by?(user, category)
    is_for_both? && self.user == user && self.category == category
  end

















  # fixme: this occur n+1
  # 手渡し料金表示画面で今月の料金を計算するメソッド
  def self.both_this_month(current_user, partner)
    current_user.expenses.this_month.both_t.sum(:mypay) + partner.expenses.this_month.both_t.sum(:partnerpay) - current_user.expenses.this_month.both_t.sum(:amount)
  end

  # fixme: this occur n+1
  # 手渡し料金表示画面で先月の料金を計算するメソッド
  def self.both_last_month(current_user, partner)
    current_user.expenses.last_month.both_t.sum(:mypay) + partner.expenses.last_month.both_t.sum(:partnerpay) - current_user.expenses.last_month.both_t.sum(:amount)
  end

  # 新しく繰り返し出費が登録されたときに、expensesテーブルに該当する出費をインサートしていくメソッド
  def self.creat_repeat_expenses!(repeat_expense)
    expense_attributes = {}
    repeat_expense.attributes.each{ |k, v| expense_attributes["#{k}"] = v if Expense.necessary_attributes_from_repeat_exepnses.include?(k) }
    s_date = repeat_expense.updated_only_future? ? Date.current : repeat_expense.s_date
    e_date = repeat_expense.e_date
    r_date = repeat_expense.r_date
    (s_date..e_date).select{|d| d.day == r_date }.each do |date|
      expense = Expense.new(expense_attributes)
      expense.date = date
      expense.repeat_expense_id = repeat_expense.id
      expense.save!
    end
  end

  # 繰り返し出費の更新のときのためのメソッド。方針が決まらず、途中
  def self.update_repeat_expense(old, repeat_expense, expense_params)
    today = Date.today
    old_s_date = old.s_date
    old_e_date = old.e_date
    old_r_date = old.r_date
    s_date = repeat_expense.s_date
    e_date = repeat_expense.e_date
    r_date = repeat_expense.r_date
    if today < s_date
      old_records = user.expenses.where(repeat_expense_id: repeat_expense.id)
      old_records.destroy_all
      creat_repeat_expenses(s_date, r_date, e_date, repeat_expense, expense_params)
    elsif today > e_date
      old_records = user.expenses.where('repeat_expense_id = ? AND date > ?', repeat_expense.id, e_date)
      old_records.destroy_all
    # elsif today > s_date && today < e_date

    end
  end

  # 繰り返し出費を消したときのそれに紐づいているexpensesを消去するメソッド
  # 当月以降のexpensesは消去。当月以前のexpensesは残す
  def self.destroy_repeat_expenses(user, repeat_expense_id)
    future_expenses = user.expenses.where('repeat_expense_id = ? AND date >= ?', repeat_expense_id, Date.today.beginning_of_month)
    future_expenses.destroy_all
    past_expenses = user.expenses.where('repeat_expense_id = ? AND date <= ?', repeat_expense_id, Date.today.beginning_of_month)
    past_expenses.update(repeat_expense_id: nil)
  end

end
