xml.instruct!
xml.feed "xmlns" => "http://www.w3.org/2005/Atom" do
  site_url = NLog2.config[:blog][:url]
  xml.title NLog2.config[:blog][:title]
  if (subtitle = NLog2.config[:blog][:subtitle])
    xml.subtitle subtitle
  end
  xml.id site_url
  xml.link "href" => site_url
  xml.link "href" => URI.join(site_url, "feed.xml"), "rel" => "self"
  xml.updated(@feed_posts.first.updated_at.iso8601) unless @feed_posts.empty?
  xml.author { xml.name NLog2.config[:blog][:author] }

  @feed_posts.each do |post|
    xml.entry do
      xml.title post.title
      xml.link "rel" => "alternate", "href" => post.url
      xml.id post.url
      xml.published post.published_at.iso8601
      xml.updated post.updated_at.iso8601
      xml.author { xml.name NLog2.config[:blog][:author] }
      # xml.summary article.summary, "type" => "html"
      xml.content post.rendered_body, "type" => "html"
    end
  end
end

