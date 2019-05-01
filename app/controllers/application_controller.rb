class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :check_logging_in
  before_action :check_partner
  before_action { count_header_notifications if logged_in? && @partner.present? }
  helper_method :current_user, :partner, :logged_in?

  def current_user
    user = User.find_by(id: session[:user_id])
    if @current_user.present? && session[:patner_mode]
      @current_user = user.partner
    else
      @current_user = user
    end
  end

  def logged_in?
    !current_user.nil?
  end

  def check_logging_in
    unless logged_in?
      redirect_to login_path
    end
  end

  def partner
    @partner ||= current_user.partner
  end

  def check_partner
    unless have_partner?
      redirect_to edit_user_path
    end
  end

  # fixme: 通知カウントはテーブルで持つようにするとsql打たなくてもいい。
  def count_header_notifications
    @header_notifications = @partner.notifications.includes(:user, :notification_message).where(read_flg: false).order(created_at: :desc)
    @header_notification_count ||= @header_notifications.size
  end

  def users_one?(object)
    object.user == @current_user
  end

  def partners_one?(object)
    object.user == @partner
  end

  def notification_msg
    notification_msg_id = NotificationMessage.find_by(func: controller_path, act: action_name).msg_id
    return notification_msg_id
  end

  def check_need_notify(obj)
    if controller_path == "expenses" && obj.both_flg == false
      return true
    elsif controller_path == "repeat_expenses" && obj.both_flg == false
      return true
    elsif controller_path == "categories" && obj.common == false
      return true
    else
      return false
    end
  end

  #fixme: コールバックでするように移動。
  def create_notification(obj)
    unless check_need_notify(obj)
      Notification.create(user_id: current_user.id,
        notification_message_id: notification_msg,
        notified_by_id: obj.id,
        record_meta: obj.to_json
      )
    end
  end

  private
  def have_partner?
    !partner.nil?
  end
end
