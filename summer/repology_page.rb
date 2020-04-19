#!/usr/bin/ruby
# vim: set sw=4 sts=4 et tw=80 :

require 'json'

class RepologyPage
    def initialize ids
        @ids = ids
        @name = "repology"
        @dir = OutputDir
        @filename = @dir + @name + ".json"
    end

    def ensure_output_dir
        begin
            Pathname.new(@dir).mkpath
        rescue Errno::EEXIST
        end
    end

    def metadata_key_to_string key
        case key
        when MetadataStringKey
            key.parse_value

        when MetadataStringSetKey, MetadataStringSequenceKey
            key.parse_value.join(', ')

        when MetadataSimpleURISpecTreeKey, MetadataDependencySpecTreeKey, MetadataFetchableURISpecTreeKey,
            MetadataPlainTextSpecTreeKey, MetadataLicenseSpecTreeKey
            result = []
            lambda do | recurse, value |
                case value
                when nil
                    # might've been normalised to nothing
                when AllDepSpec, AllDepSpec, ConditionalDepSpec
                    value.each do | child |
                        recurse.call(recurse, child)
                    end

                when SimpleURIDepSpec
                    result << value.text

                end
            end.tap do | x |
                x.call(x, key.parse_value)
            end
            result.join(" ")
        end
    end

    def metadata id
        ret = {}
        id.each_metadata do | key |
            case key.raw_name
            when "HOMEPAGE"
                ret["homepage"] = metadata_key_to_string key
            end
        end
        ret
    end

    def id_to_json id
        m = {
            "name" => id.name.package,
            "category" => id.name.category,
            "version" => id.version,
            "summary" => id.short_description_key ?
                id.short_description_key.parse_value.sub(/\.$/, '').force_encoding("UTF-8") :
                id.name.package,
        }
        m.merge(metadata(id)).to_json
    end

    def generate_json
        '[' + @ids.map do | id |
            begin
                id_to_json(id)
            rescue Encoding::UndefinedConversionError
                $stderr << "Weird encoding in metadata for: " << id.name << "\n"
            end
        end.join(",") + ']'
    end

    def generate
        ensure_output_dir

        File.open(@filename, "w") do | file |
            file << generate_json
        end
    end
end
