# == Schema Information
#
# Table name: users
#
#  id         :bigint           not null, primary key
#  email      :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_users_on_email  (email) UNIQUE
#
class User < ApplicationRecord
    validates :email, uniqueness: true, presence: true

    has_many :submitted_urls,
        primary_key: :id,
        class_name: :ShortenedUrl,
        foreign_key: :submitter_id

    has_many :visits,
        primary_key: :id,
        class_name: :Visit,
        foreign_key: :user_id

    has_many :visited_urls,
        -> { distinct },
        through: :visits,
        source: :shortened_url
end
