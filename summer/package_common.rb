#!/usr/bin/ruby
# vim: set sw=4 sts=4 et tw=80 :

module Summer
    module PackageCommon
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
end
