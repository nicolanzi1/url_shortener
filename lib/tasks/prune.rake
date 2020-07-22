namespace :prune do
    task old_urls: :environment do
        minutes = ENV['minutes'].to_i || 144
        puts "Prunning old urls..."
        ShortenedUrl.prune(minutes)
    end
end