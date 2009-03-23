#!/usr/bin/ruby
# vim: set sw=4 sts=4 et tw=80 :

require 'Paludis'
require 'pathname'
require 'fileutils'

include Paludis

EnvironmentSpec = ":summer"
OutputDir = "./output/"
ExtraFiles = %w[screen.css summer.css zebrapig-headbox.png]
Platforms = %w[amd64 ia64 ppc64 x86]

class HTMLString
    def initialize s
        @s = s
    end

    def to_html
        @s
    end

    def + s
        if s.respond_to? :to_html
            HTMLString.new(to_html + s.to_html)
        else
            HTMLString.new(to_html + self.class.escape(s.to_s))
        end
    end

    def << s
        if s.respond_to? :to_html
            @s << s.to_html.to_s
        else
            @s << self.class.escape(s.to_s)
        end
        self
    end

    def self.escape s
        result = s
        result.gsub! '&', '&amp;'
        result.gsub! '<', '&lt;'
        result.gsub! '>', '&gt;'
        result
    end
end

def html s
    HTMLString.new(s)
end

class Page
    def initialize name
        @dir = OutputDir + name.to_s
        @filename = @dir + "/index.html"
    end

    def self.make_header(top_uri, title)
        @@header ||= nil
        unless @@header
            File.open("header.html", "r") do | file |
                @@header = file.read
            end
        end

        @@header.gsub('@@TITLE@@', title).gsub('@@TOPURI@@', top_uri)
    end

    def make_header title
        self.class.make_header(top_uri, title)
    end

    def self.make_content(content)
        @@content ||= nil
        unless @@content
            File.open("content.html", "r") do | file |
                @@content = file.read
            end
        end

        @@content.gsub('@@CONTENT@@', content)
    end

    def make_content c
        self.class.make_content(c)
    end

    def self.make_footer()
        @@footer ||= nil
        unless @@footer
            File.open("footer.html", "r") do | file |
                @@footer = file.read
            end
        end

        @@footer
    end

    def make_footer
        self.class.make_footer
    end

    def generate
        begin
            Pathname.new(@dir).mkpath
        rescue Errno::EEXIST
        end

        File.open(@filename, "w") do | file |
            file << make_header(title.to_html)
            file << make_content(content.to_html)
            file << make_footer()
        end
    end
end

class ChildPage < Page
    def initialize name
        super name
        @in_repos = Hash.new
    end

    def is_in_repository repo
        @in_repos[repo] = true
    end
end

class CategoryPage < ChildPage
    def initialize cat
        super "packages/" + cat
        @cat = cat
        @pkgs = Hash.new
    end

    def has_package pkg
        @pkgs[pkg] = true
    end

    def title
        return html("") + @cat
    end

    def content
        @pkgs.keys.sort.inject(html("<ul>\n")) do | txt, pkg |
            txt + html('<li><a href="') + pkg.package + html('/index.html">') + pkg.package + html("</a></li>\n")
        end + html("</ul>\n")
    end

    def top_uri
        "../../"
    end
end

class PackagePage < ChildPage
    def initialize pkg
        super "packages/" + pkg
        @pkg = pkg
        @ids = Hash.new
    end

    def has_id id
        @ids[id] = true
    end

    def title
        return html("") + @pkg
    end

    def content
        txt = html("")

        best_id = @ids.keys.max_by do | id |
            id.version.is_scm? ? VersionSpec.new("0") : id.version
        end

        if best_id.short_description_key
            txt << html("<p>") << best_id.short_description_key.value << html("</p>\n")
        end

        txt << html("<h2>Versions</h2>\n")

        slots = Hash.new
        @ids.keys.each do | id |
            (slots[id.slot_key ? id.slot_key.value : "?"] ||= []) << id
        end

        txt << html(<<-END .gsub('SPAN', 'span="' + Platforms.length.to_s + '"')
            <table class="packages">
                <col width="1*" />
                <col width="2*" />
                <col width="3*" />
                <colgroup SPAN width="1*" />
                <tr>
                    <th>Slot</th>
                    <th>Version</th>
                    <th>Repository</th>
                    <th colSPAN>Platforms</th>
                </tr>
            END
            )

        slots.keys.sort_by do | slot |
            slots[slot].max_by do | id |
                id.version
            end.version
        end.reverse.each do | slot |
            versions = slots[slot].sort_by do | id |
                id.version
            end.reverse

            txt << html("<tr class='newslot'><th rowspan='") << versions.length << html("'>") << slot << html("</th>")
            txt << versions.map do | ver |
                Platforms.inject(((ver == best_id and @ids.length > 1) ?
                                  html("<td class='best-id'>") :
                                  html("<td>")) +
                                  ver.version + html("</td><td>") + ver.repository_name +
                                  html("</td>")) do | t, platform |
                    if ver.keywords_key
                        if ver.keywords_key.value.include? platform
                            t + html("<td class='platform-stable'>") + platform + html("</td>")
                        elsif ver.keywords_key.value.include?("~" + platform)
                            t + html("<td class='platform-unstable'>") + "~" + platform + html("</td>")
                        elsif ver.keywords_key.value.include?("-" + platform)
                            t + html("<td class='platform-disabled'>") + "-" + platform + html("</td>")
                        elsif ver.keywords_key.value.include?("-*")
                            t + html("<td class='platform-disabled'>") + "-*" + html("</td>")
                        else
                            t + html("<td class='platform-unkeyworded'>") + platform + "?" + html("</td>")
                        end
                    else
                        t + html("<td class='platform-unkeyworded'>") + "???" + html("</td>")
                    end
                end
            end.inject(nil) do | t, item |
                if t
                    t + html("</tr>\n<tr class='sameslot'>") + item
                else
                    item
                end
            end
        end

        txt << html(<<-END
            </table>
        END
        )

        txt << html("<h2>Metadata</h2>\n<dl>\n")

        keys = []
        best_id.each_metadata do | key |
            keys << key
        end

        keys.sort_by do | key |
            [key.type, key.human_name]
        end.each do | key |
            next if key.raw_name == best_id.choices_key.raw_name

            case key.type
            when MetadataKeyType::Internal
                next
            when MetadataKeyType::Significant
                txt << html("<dt class='significant'>") << key.human_name << html("</dt>")
            else
                txt << html("<dt>") << key.human_name << html("</dt>")
            end

            case key
            when MetadataStringKey
                txt << html("<dd>") << key.value << html("</dd>")

            when MetadataStringSetKey, MetadataStringSequenceKey
                txt << html("<dd>") << key.value.join(', ') << html("</dd>")

            when MetadataSimpleURISpecTreeKey, MetadataDependencySpecTreeKey, MetadataFetchableURISpecTreeKey,
                MetadataPlainTextSpecTreeKey
                txt << html("<dd>")
                lambda do | recurse, value, top |
                    case value
                    when AllDepSpec
                        recursive_top = top and not value.find do | child |
                            not child.kind_of? AllDepSpec
                        end

                        txt << "( " unless top
                        value.each do | child |
                            recurse.call(recurse, child, recursive_top)
                        end
                        txt << ") " unless top

                    when AnyDepSpec
                        txt << "|| ( "
                        value.each do | child |
                            recurse.call(recurse, child, false)
                        end
                        txt << ") "

                    when ConditionalDepSpec
                        txt << value << " ( "
                        value.each do | child |
                            recurse.call(recurse, child, false)
                        end
                        txt << ") "

                    when SimpleURIDepSpec
                        txt << html("<a href='") << value.text << html("'>") << value.text << html("</a> ")

                    when FetchableURIDepSpec
                        txt << html("<a href='http://distfiles.exherbo.org/") << value.filename <<
                            html("'>") << value.text << html("</a> ")

                    when PackageDepSpec
                        txt << html("<a href='../../") << value.package << html("/index.html'>") <<
                            value.to_s << html("</a> ")

                    when PlainTextDepSpec, URILabelsDepSpec, PlainTextLabelDepSpec, DependencyLabelsDepSpec,
                        BlockDepSpec
                        txt << value.to_s << " "

                    else
                        $stderr << "unsupported spec tree thing: " << value.class << "\n"
                        txt << html("<span class='unsupported'>") << value.to_s <<
                            html("</span> ")
                    end
                end.tap do | x |
                    x.call(x, key.value, true)
                end
                txt << html("</dd>")

            else
                $stderr << "unsupported key thing: " << key.class << "\n"
                txt << html("<dd>Don't know how to show this yet: <span class='unsupported'>") <<
                    key.inspect << html("</span></dd>")
            end
        end

        txt << html("</dl>\n")

        txt << html("<h2>Choices</h2>\n")

        best_id.choices_key.value.each do | choice |
            choice.hidden? and next
            choice.human_name == "Build Options" and next

            header = lambda do
                txt << html("<h3>") << choice.human_name << html("</h3>\n") << html(<<-END )
                    <table class="choices">
                END
            end

            footer = lambda {}

            choice.each do | value |
                value.explicitly_listed? or next

                header.call
                header = lambda {}
                footer = lambda do
                    txt << html(<<-END )
                        </table>
                    END
                end

                txt << html("<tr><td>") << value.unprefixed_name << html("</td><td>") <<
                    value.description << html("</td></tr>\n")
            end

            footer.call
        end

        txt
    end

    def top_uri
        "../../../"
    end
end

class IndexPage < Page
    def initialize
        super ""
        @repos = Hash.new
        @cats = Hash.new
    end

    def has_repository repo
        @repos[repo] = true
    end

    def has_category cat
        @cats[cat] = true
    end

    def title
        return html("Statically Updated Metadata Manifestation for Exherbo Repositories")
    end

    def content
        txt = html("<h2>Categories</h2>\n")

        txt << html(<<-END )
            <table class="categories">
                <colgroup span="5" width="1*" />
                <tr>
        END

        n = 0
        @cats.keys.sort.each do | cat |
            txt << html('<td><a href="packages/') << cat << html('/index.html">') <<
                html(html(cat.to_s).to_html.gsub("-", '&#8209;')) << html("</a></td>\n")
            if ((n += 1) == 5)
                n = 0
                txt << html('</tr><tr>')
            end
        end

        txt << html(<<-END )
                </tr>
            </table>
        END

        txt
    end

    def top_uri
        ""
    end
end

puts "Querying..."
env = EnvironmentFactory.instance.create(EnvironmentSpec)
ids = env[Selection::AllVersionsSorted.new(Generator::All.new | Filter::SupportsAction.new(InstallAction))]

category_pages, package_pages = Hash.new, Hash.new
index_page = IndexPage.new

print "IDs"
ids.each do | id |
    print "."
    $stdout.flush

    index_page.has_repository(id.repository_name)
    index_page.has_category(id.name.category)

    cat_page = (category_pages[id.name.category] ||= CategoryPage.new(id.name.category))
    cat_page.has_package(id.name)
    cat_page.is_in_repository(id.repository_name)

    pkg_page = (package_pages[id.name] ||= PackagePage.new(id.name))
    pkg_page.has_id(id)
    pkg_page.is_in_repository(id.repository_name)
end
puts

print "Copying extra bits"
FileUtils.cp ExtraFiles, OutputDir
puts

print "Writing"
[[index_page], category_pages.values, package_pages.values].each do | set |
    set.each do | page |
        print "."
        $stdout.flush
        page.generate
    end
end
puts

