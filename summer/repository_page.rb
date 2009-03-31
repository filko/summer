#!/usr/bin/ruby
# vim: set sw=4 sts=4 et tw=80 :

require 'summer/templated_page'

class RepositoryPage < TemplatedPage
    def initialize repo
        super "repositories/" + repo.name
        @repository = repo
        @packages = {}
    end

    def page_title
        return @repository.name
    end

    def add_id id
        (@packages[id.name] ||= []) << id
    end

    def self.content_template_filename
        return "summer/repository_page.rhtml"
    end

    def self.get_template_variables_hash
        {
            :metadata_keys             => :get_interesting_metadata_keys,
            :summary                   => :get_summary_key_value,
            :key_value                 => :metadata_key_value_to_html,
            :package_names             => :get_package_names,
            :package_href              => :make_package_href,
            :package_summary           => :make_package_summary
        }
    end

    def top_uri
        return "../../"
    end

    def is_interesting_key? key
        if key.type == MetadataKeyType::Significant
            not %w{location summary}.include? key.human_name
        else
            %w{sync}.include? key.human_name
        end
    end

    def get_interesting_metadata_keys
        result = []
        @repository.each_metadata do | key |
            result << key if is_interesting_key? key
        end
        result.sort_by do | key |
            [ key.type, key.human_name ]
        end
    end

    def get_summary_key_value
        if @repository['summary']
            @repository['summary'].value
        else
            nil
        end
    end

    def get_package_names
        @packages.keys.sort
    end

    def make_package_href name
        return top_uri + "packages/" + name + "/index.html"
    end

    def make_package_summary name
        best_id = best_id_for name
        if best_id.short_description_key
            best_id.short_description_key.value.sub(/\.$/, '')
        else
            name.to_s
        end
    end

    def best_id_for name
        @packages[name].max_by do | id |
            [ id.version.is_scm? ? 0 : 1 , id.version ]
        end
    end
end

