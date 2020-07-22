# == Schema Information
#
# Table name: tag_topics
#
#  id         :bigint           not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class TagTopic < ApplicationRecord
    validates :name, presence: true

    has_many :taggings,
        primary_key: :id,
        class_name: :Tagging,
        foreign_key: :tag_topic_id,
        dependent: :destroy

    has_many :shortened_urls,
        through: :taggings,
        source: :shortened_url

    def popular_links
        shortened_urls.joins(:visits)
            .group(:short_url, :long_url)
            .order('COUNT(visits.id) DESC')
            .select('long_url, short_url, COUNT(visit.id) as number_of_visits')
            .limit(5)
    end
end
