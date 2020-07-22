# == Schema Information
#
# Table name: shortened_urls
#
#  id           :bigint           not null, primary key
#  long_url     :string           not null
#  short_url    :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  submitter_id :integer          not null
#
# Indexes
#
#  index_shortened_urls_on_short_url     (short_url) UNIQUE
#  index_shortened_urls_on_submitter_id  (submitter_id)
#
class ShortenedUrl < ApplicationRecord
    validates :long_url, :short_url, :submitter, presence: true
    validates :short_url, uniqueness: true
    
    belongs_to :submitter,
        primary_key: :id,
        class_name: :User,
        foreign_key: :submitter_id
    
    has_many :visits,
        primary_key: :id,
        class_name: :Visit,
        foreign_key: :shortened_url_id

    has_many :visitors,
        -> { distinct } # ->(lambda literal) = Proc.new
        through: :visits,
        source: :visitor

    def self.create_for_user_and_long_url!(user, long_url)
        ShortenedUrl.create!(
            submitter_id: user.id,
            long_url: long_url,
            short_url: ShortenedUrl.random_code
        )
    end
    
    def self.random_code
        loop do
        random_code = SecureRandom.urlsafe_base64(16)
        return random_code unless ShortenedUrl.exists?(short_url: random_code)
        end
    end

    def num_clicks
        visits.count
    end

    def num_uniques
        visits.select('user_id').distinct.count
    end

    def num_recent_uniques
        visits
            .select('user_id')
            .where('created_at > ?', 10.minutes.ago)
            .distinct
            .count
    end
end
