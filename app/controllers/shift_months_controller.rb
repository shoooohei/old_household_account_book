class ShiftMonthsController < ApplicationController
  before_action :check_logging_in
  before_action :check_partner

  def past
    @cnum = params[:id].to_i - 1
    if @cnum == 0
      redirect_to expenses_path
    else
      past_and_future(@cnum)
    end
  end

  def future
    @cnum = params[:id].to_i + 1
    if @cnum == 0
      redirect_to expenses_path
    else
      past_and_future(@cnum)
    end
  end

  def past_and_future(cnum)
    @current_user_expenses = ShiftMonth.ones_expenses(current_user, cnum)
    @current_user_expenses_of_both = ShiftMonth.ones_expenses_of_both(current_user, cnum)
    @partner_expenses_of_both = ShiftMonth.ones_expenses_of_both(partner, cnum)
    @sum = @current_user_expenses.sum(:amount)
    @both_sum = ShiftMonth.must_pay_one_month(current_user, partner, cnum)
    @category_sums = Expense.category_sums(@current_user_expenses, @current_user_expenses_of_both, @partner_expenses_of_both)
    @category_badgets = current_user.badgets
  end
end