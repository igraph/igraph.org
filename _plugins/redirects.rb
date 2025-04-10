require "pathname"
require "shellwords"

def latest_version_in(dir)
  return nil if not File.directory?(dir)
  Pathname(dir).children.select(&:directory?).map {
    |pn| pn.basename.to_s
  }.filter {
    |name| name.match?(/^\d/)
  }.sort_by {
    |v| Gem::Version.new(v)
  }.last
end

Jekyll::Hooks.register :site, :after_reset do |site|
  system "find #{Shellwords.escape(site.dest)} -type l | xargs -r rm"
end

Jekyll::Hooks.register :site, :post_write do |site|
  puts "  Creating links..."
  links = {
    "c/html/latest" => latest_version_in(File.join(site.source, "c", "html")),
    "c/pdf/latest" => latest_version_in(File.join(site.source, "c", "pdf")),
    "c/doc" => "html/latest",
    "r/html/latest" => latest_version_in(File.join(site.source, "r", "html")),
    "r/pdf/latest" => latest_version_in(File.join(site.source, "r", "pdf")),
    "r/doc" => "html/latest",
    "python/api/latest" => latest_version_in(File.join(site.source, "python", "api")),
    "python/doc/api" => "../api/latest",
    "python/doc/tutorial" => "../tutorial/latest",
    "python/versions/latest" => latest_version_in(File.join(site.source, "python", "versions")),

    # special case: python/tutorial/X was moved to
    # python/versions/X/tutorial.html from version 0.10 onwards so we need to
    # look there
    # "python/tutorial/latest" => File.join(
    #   "..", "versions",
    #   latest_version_in(File.join(site.source, "python", "versions")),
    #   "tutorial.html"
    # )
  }
  Dir.chdir(site.dest) do
    links.each_pair { |key, value|
      if value
        # Create directories for the key if they don't exist
        FileUtils.mkdir_p(key)

        # Resolve "value" to an absolute path
        value = File.expand_path(value, File.dirname(File.join(site.dest, key))).delete_prefix(site.dest)

        # Generate an HTML redirect page
        File.open("#{key}/index.html", "w") do |file|
          file.write <<~HTML
            <!DOCTYPE html>
            <html>
            <head>
              <meta http-equiv="refresh" content="0; url=#{value}/" />
              <link rel="canonical" href="#{value}/" />
            </head>
            <body>
              <p>If you are not redirected automatically, follow this <a href="#{value}/">link</a>.</p>
            </body>
            </html>
          HTML
        end
      end
    }
  end
end
