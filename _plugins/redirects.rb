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
  puts "  Duplicating content to simulate symlinks..."
  links = {
    # values are relative paths anchored at the key, not at site.dest

    "c/html/latest" => latest_version_in(File.join(site.source, "c", "html")),
    "c/pdf/latest" => latest_version_in(File.join(site.source, "c", "pdf")),
    "r/html/latest" => latest_version_in(File.join(site.source, "r", "html")),
    "r/pdf/latest" => latest_version_in(File.join(site.source, "r", "pdf")),
    "python/api/latest" => latest_version_in(File.join(site.source, "python", "api")),
    "python/versions/latest" => latest_version_in(File.join(site.source, "python", "versions")),

    "c/doc" => "html/latest",
    "r/doc" => "html/latest",
  }
  Dir.chdir(site.dest) do
    links.each_pair { |key, value|
      dest = File.join(site.dest, key)
      src = File.expand_path(value, File.dirname(File.join(site.dest, key)))
      preserve = true
      dereference_root = true
      remove_destination = true

      FileUtils.copy_entry(src, dest, preserve, dereference_root, remove_destination)
    }
  end

  puts "  Creating client-side redirects..."
  links = {
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
