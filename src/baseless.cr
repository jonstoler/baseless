require "yaml"
require "crustache"

unless Dir.exists? "schemes"
	puts "Schemes directory does not exist."
	exit 1
end

unless Dir.exists? "templates"
	puts "Templates directory does not exist."
	exit 1
end

bases = \
["base00", "base01", "base02", "base03",
 "base04", "base05", "base06", "base07",
 "base08", "base09", "base0A", "base0B",
 "base0C", "base0D", "base0E", "base0F"]

templates = Dir.entries("templates") - [".", ".."]
schemes   = Dir.entries("schemes") - [".", ".."]

templates.each do |template|
	schemes.each do |scheme|
		Dir.glob("schemes/#{scheme}/*.yaml").each do |s|
			unless File.readable? s
				puts "WARNING: Cannot read scheme #{s}, skipping."
				next
			end

			scheme_data = YAML.parse File.read s
			template_data = {} of String => String

			scheme_slug = scheme_data["scheme"].as_s.downcase.strip.gsub(' ', "-")

			template_data["scheme-name"] = scheme_data["scheme"].as_s
			template_data["scheme-author"] = scheme_data["author"].as_s
			template_data["scheme-slug"] = scheme_slug

			bases.each do |base|
				color = scheme_data[base].as_s.to_i(16)
				base_r = (color & 0xff0000) >> 16
				base_g = (color & 0xff00) >> 8
				base_b = (color & 0xff) >> 0
				
				template_data["#{base}-hex"] = scheme_data[base].as_s
				template_data["#{base}-rgb-r"] = base_r.to_s
				template_data["#{base}-rgb-g"] = base_g.to_s
				template_data["#{base}-rgb-b"] = base_b.to_s
				template_data["#{base}-hex-r"] = base_r.to_s(16)
				template_data["#{base}-hex-g"] = base_g.to_s(16)
				template_data["#{base}-hex-b"] = base_b.to_s(16)
			end

			template_config_path = "templates/#{template}/templates/config.yaml"
			unless File.exists? template_config_path
				puts "WARNING: No template configuration file found at #{template_config_path}. This template will be skipped."
				break
			end
			unless File.readable? template_config_path
				puts "WARNING: Cannot read template configuration #{template_config_path}. This template will be skipped."
				break
			end

			template_config = YAML.parse File.read template_config_path

			template_config.each do |output|
				output_extension = template_config[output.as_s]["extension"].as_s
				output_directory = template_config[output.as_s]["output"].as_s

				template_path = "templates/#{template}/templates/#{output}.mustache"
				unless File.exists? template_path
					puts "WARNING: No template found at #{template_path}. This template will be skipped."
					next
				end

				template_parsed = Crustache.parse File.read template_path
				template_rendered = Crustache.render template_parsed, template_data

				Dir.mkdir_p "out/#{output_directory}"
				File.write "out/#{output_directory}/base16-#{scheme_slug}#{output_extension}", template_rendered
			end
		end
	end
end
