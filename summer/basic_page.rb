#!/usr/bin/ruby
# vim: set sw=4 sts=4 et tw=80 :

require 'summer/abstract_method'
require 'summer/methods_from_instance_methods'
require 'summer/method_maker'
require 'pathname'
require 'erb'

class BasicPage
    def initialize name
        @name = name.to_s
        @dir = OutputDir + @name
        @filename = @dir + "/index.html"
    end

    abstract_method :page_title, :top_uri, :generate_content

    def ensure_output_dir
        begin
            Pathname.new(@dir).mkpath
        rescue Errno::EEXIST
        end
    end

    def self.escape_html *args
        ERB::Util::h(*args)
    end

    def escape_html *args
        self.class.escape_html *args
    end

    def self.generate_part_method_1 arg
        send :define_method, "generate_#{arg.to_s}".to_sym do
            send("get_#{arg.to_s}_template".to_sym).result(
                methods_from_instance_methods(self, {
                    :title => :page_title,
                    :top_uri => :top_uri,
                    :h => :escape_html
                }))
        end
    end

    def self.get_template_method_1 arg
        send :define_method, "get_#{arg.to_s}_template".to_sym do
            self.class.send "cached_get_#{arg.to_s}_template".to_sym
        end
    end

    def self.cached_get_template_method_1 arg
        self.class.send :define_method, "cached_get_#{arg.to_s}_template".to_sym do
            iv = "@cache_template_#{arg.to_s}".to_sym
            result = instance_variable_get iv
            unless result
                File.open("summer/" + arg.to_s + ".rhtml", "r") do | file |
                    result = ERB.new(file.read)
                end
                instance_variable_set iv, result
            end
            result
        end
    end

    [ :generate_part_method, :get_template_method, :cached_get_template_method ].each do | m |
        method_maker m
        self.send m, :header, :footer
    end

    def generate_all
        generate_header + generate_content + generate_footer
    end

    def generate
        ensure_output_dir

        File.open(@filename, "w") do | file |
            file << generate_all
        end
    end

    def skip_boring_specs spec
        return spec unless spec.kind_of? AllDepSpec

        first = nil
        spec.each do | s |
            return spec if first
            first = s
        end

        skip_boring_specs first
    end

    def metadata_key_value_to_html key
        case key
        when MetadataStringKey
            escape_html(key.value)

        when MetadataStringSetKey, MetadataStringSequenceKey
            escape_html(key.value.join(', '))

        when MetadataStringStringMapKey
            escape_html(key.value.map { | k, v | k + (k.empty? ? "" : ": ") + v }.join(" "))

        when MetadataSimpleURISpecTreeKey, MetadataDependencySpecTreeKey, MetadataFetchableURISpecTreeKey,
                MetadataPlainTextSpecTreeKey, MetadataLicenseSpecTreeKey
            result = ""
            lambda do | recurse, value, indent |
                result << indent
                case value
                when nil
                    # might've been normalised to nothing
                when AllDepSpec
                    result << "( <br />"
                    value.each do | child |
                        recurse.call(recurse, child, indent + " &nbsp; &nbsp; ")
                    end
                    result << indent << ") "

                when AnyDepSpec
                    result << "|| ( <br />"
                    value.each do | child |
                        recurse.call(recurse, child, indent + " &nbsp; &nbsp; ")
                    end
                    result << indent << ") "

                when ConditionalDepSpec
                    result << escape_html(value.to_s) << " ( <br />"
                    value.each do | child |
                        recurse.call(recurse, child, indent + " &nbsp; &nbsp; ")
                    end
                    result << indent << ") "

                when SimpleURIDepSpec
                    result << "<a href='" << escape_html(value.text) << "'>" << escape_html(value.text) <<
                        "</a> "

                when FetchableURIDepSpec
                    result << "<a href='http://distfiles.exherbo.org/distfiles/" << escape_html(value.filename) <<
                        "'>" << escape_html(value.text) << "</a> "

                when PackageDepSpec
                    result << "<a href='" << top_uri << "packages/" << escape_html(value.package) << "/index.html'>" <<
                        escape_html(value.to_s) << "</a> "

                when PlainTextDepSpec, URILabelsDepSpec, PlainTextLabelDepSpec, DependenciesLabelsDepSpec,
                    BlockDepSpec, LicenseDepSpec
                    result << value.to_s << " "

                else
                    $stderr << "unsupported spec tree thing: " << value.class << "\n"
                    result << "<span class='unsupported'>" << escape_html(value.to_s) << "</span>"
                end

                if value.respond_to? :annotations_key and value.annotations_key
                    first = true
                    value.annotations_key.each_metadata do | child |
                        result << " [[<br />" if first
                        first = false
                        result << indent << " &nbsp; &nbsp; " << escape_html(child.raw_name) <<
                            " = [ " << escape_html(child.value) << " ]<br />"
                    end
                    result << indent << "]]" unless first
                end

                result << "<br />"
            end.tap do | x |
                x.call(x, skip_boring_specs(key.value), "")
            end

            result.sub(%r[<br />$], '')

        else
            $stderr << "unsupported key thing: " << key.class << "\n"
            "Don't know how to show this yet: <span class='unsupported'>" +
                escape_html(key.inspect) + "</span>"
        end
    end
end

