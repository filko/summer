#!/usr/bin/ruby
# vim: set sw=4 sts=4 et tw=80 :

require 'summer/templated_page'
require 'summer/package_common.rb'

class RepositoryPage < TemplatedPage
    include Summer::PackageCommon

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
            :masters                   => :get_masters,
            :summary                   => :get_summary_key_value,
            :key_value                 => :metadata_key_value_to_html,
            :package_names             => :get_package_names,
            :package_href              => :make_package_href,
            :package_summary           => :make_package_summary,
            :repository_href           => :make_repository_href
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

    def get_masters
        if @repository['master_repository']
            @repository['master_repository'].value
        else
            []
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
end

