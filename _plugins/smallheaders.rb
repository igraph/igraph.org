# Smaller Hx HTML tags
module Jekyll
  module SmallHeaderFilter
    def smallheaders(input)
      input.gsub(/<h3([^>]*>.*)<\/h3>/m, "<h4\\1</h4>")
        .gsub(/<h2([^>]*>.*)<\/h2>/m, "<h3\\1</h3>")
        .gsub(/<h1([^>]*>.*)<\/h1>/m, "<h2\\1</h2>")
    end
  end
end

Liquid::Template.register_filter(Jekyll::SmallHeaderFilter)
