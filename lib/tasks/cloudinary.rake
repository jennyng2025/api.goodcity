namespace :cloudinary do
  # tag value can be "development"/"staging"/"offer_#{id}"/
  # list of comma seperated tags: "offer_163, offer_164"
  # rake cloudinary:delete tag=development
  desc 'clean cloudinary images'
  task delete: :environment do
    if ENV['tag']
      tag_names = ENV['tag'].split(",").map(&:strip)
      tag_names.each do |tag|
        response = Cloudinary::Api.delete_resources_by_tag(tag)
        puts "Deleted #{response["deleted"].count} images with tag #{tag}."
      end
    end
  end

  desc "List cloudinary tags"
  task list_tags: :environment do
    tags = []
    next_cursor = nil
    while true do
      list = Cloudinary::Api.tags(max_results: 500, next_cursor: next_cursor)
      tags << list["tags"]
      next_cursor = list[:next_cursor]
      break if next_cursor.nil?
    end
    puts tags.uniq.compact
  end

end
