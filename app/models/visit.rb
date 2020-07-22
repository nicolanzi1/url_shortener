class Visit < ApplicationRecord
    validates :visitor, :shortened_url, presence: true

    belongs_to :shortened_url

    belongs_to :visitor,
        primary_key: :id,
        class_name: :User,
        foreign_key: :user_id

    def self.record_visit!(user, shortened_url)
        Visit.create!(
            user_id: user.id,
            shortened_url_id: shortened_url.id
        )
    end
end