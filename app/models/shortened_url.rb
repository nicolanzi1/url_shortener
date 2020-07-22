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

    has_many :taggings,
        primary_key: :id,
        class_name: :Tagging,
        foreign_key: :shortened_url_id,
        dependent: :destroy

    has_many :tag_topics,
        through: :taggings,
        source: :tag_topics
    
    has_many :visits,
        primary_key: :id,
        class_name: :Visit,
        foreign_key: :shortened_url_id,
        dependent: :destroy

    has_many :visitors,
        -> { distinct }, # ->(lambda literal) = Proc.new
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

    def self.prune(n)
        ShortenedUrl
            .joins(:submitter)
            .joins('LEFT JOIN visits ON visits.shortened_url_id = shortened_urls.id')
            .where("(shortened_urls.id IN (
                SELECT shortened_urls.id
                FROM shortened_urls
                JOIN visits
                ON visits.shortened_url_id = shortened_urls.id
                GROUP BY shortened_urls.id
                HAVING MAX(visits.created_at) < \'#{n.minute.ago}\'
            ) OR (
                visits.id IS NULL and shortened_urls.created_at < \'#{n.minutes.ago}\'
            )) AND users.premium = \'f\'")
            .destroy_all

    # SQL query woudl be:

    # SELECT shortened_urls.*
    # FROM shortened_urls
    # JOIN users ON users.id = shortened_urls.submitter_id
    # LEFT JOIN visits ON visits.shortened_url_id = shortened_urls.id
    # WHERE (shortened_urls.id IN (
    #     SELECT shortened_urls.id
    #     FROM shortened_urls
    #     JOIN visits ON visits.shortened_url_id = shortened_urls.id
    #     GROUP BY shortened_urls.id
    #     HAVING MAX(visits.created_at) < "#{n.minute.ago}"
    #     ) OR (
    #         visits.id IS NULL and shortened_urls.created_at < "#{n.minutes.ago}"
    # )) AND users.premium = 'f'
    end
    
    private

    def no_spamming
        last_minute = ShortenedUrl
            .where('created_at >= ?', 1.minute.ago)
            .where(submitter_id: submitter_id)
            .length

        errors[:maximum] << 'of five short urls per minute' if last_minute >= 5
    end

    def non_premium_max
        return if User.find(self.submitter_id).non_premium_max

        number_of_urls = 
            ShortenedUrl
                .where(submitter_id: submitter_id)
                .length

        if number_of_urls >= 5
            error[:Only] << 'premium members can create more than 5 short urls'
        end
    end
end