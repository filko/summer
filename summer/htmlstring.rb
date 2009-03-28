#!/usr/bin/ruby
# vim: set sw=4 sts=4 et tw=80 :

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
        result = ""
        s.each_char do | c |
            case c
            when '&': result << '&amp;'
            when '<': result << '&lt;'
            when '>': result << '&gt;'
            when '"': result << '&quot;'
            when "'": result << '&#39;'
            else      result << c
            end
        end
        result
    end
end

def html s
    HTMLString.new(s)
end


