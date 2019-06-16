# ## Schema Information
#
# Table name: `users`
#
# ### Columns
#
# Name                   | Type               | Attributes
# ---------------------- | ------------------ | ---------------------------
# **`id`**               | `bigint(8)`        | `not null, primary key`
# **`allow_share_own`**  | `boolean`          | `default(FALSE)`
# **`email`**            | `string`           |
# **`name`**             | `string`           |
# **`password_digest`**  | `string`           |
# **`sys_admin`**        | `boolean`          | `default(FALSE)`
# **`created_at`**       | `datetime`         | `not null`
# **`updated_at`**       | `datetime`         | `not null`
#
# ### Indexes
#
# * `index_users_on_email` (_unique_):
#     * **`email`**
#

FactoryBot.define do
  factory :user do
    email {"user@gmail.com"}
    name {"user"}
    password {"asdfasdf"}
    password_confirmation {"asdfasdf"}
  end

  # 以下ではパートナーは作れない。
  # factory :partner do
  #   email {"partner@gmail.com"}
  #   name {"partner"}
  #   password {"000000"}
  #   password_confirmation {"000000"}
  #   partner {User.first}
  # end
end
