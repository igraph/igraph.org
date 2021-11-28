require "pathname"
require "shellwords"

def latest_version_in(dir)
  Pathname(dir).children.select(&:directory?).map {
    |pn| pn.basename.to_s
  }.filter {
    |name| name.match?(/^\d/)
  }.sort_by {
    |v| Gem::Version.new(v)
  }.last
end

Jekyll::Hooks.register :site, :after_reset do |site|
  system "find #{Shellwords.escape(site.dest)} -type l | xargs rm"
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
    "python/tutorial/latest" => latest_version_in(File.join(site.source, "python", "tutorial"))
  }
  Dir.chdir(site.dest) do
    links.each_pair { |key, value|
      system "ln -s #{Shellwords.escape(value)} #{Shellwords.escape(key)}"
    }
  end
end

