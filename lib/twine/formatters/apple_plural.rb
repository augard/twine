require 'plist'

module Twine
  module Formatters
    class ApplePlural < Apple
      SUPPORTS_PLURAL = true

      def format_name
        'apple-plural'
      end

      def extension
        '.stringsdict'
      end

      def default_file_name
        'Localizable.stringsdict'
      end

      def format_footer(lang)
        footer = "</dict>\n"
        footer += "</plist>\n"
      end

      def format_file(lang)
        result = super
        if result != nil 
          result += format_footer(lang)
        end
      end

      def format_header(lang)
        header = "<\?xml version=\"1.0\" encoding=\"UTF-8\"\?>\n"
        header += "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n"
        header += "<plist version=\"1.0\">\n"
        header += "<dict>\n"
      end

      def format_section_header(section)
        ""
      end

      def format_plural_keys(key, plural_hash)
        result = "#{tab(1)}<key>#{key}</key>\n"
        result += "#{tab(1)}<dict>\n"
        result += "#{tab(2)}<key>NSStringLocalizedFormatKey</key>\n"
        result += "#{tab(2)}<string>\%\#@value@</string>\n"
        result += "#{tab(2)}<key>value</key>\n#{tab(2)}<dict>\n"
        result += "#{tab(3)}<key>NSStringFormatSpecTypeKey</key>\n"
        result += "#{tab(3)}<string>NSStringPluralRuleType</string>\n"
        result += "#{tab(3)}<key>NSStringFormatValueTypeKey</key>\n"
        result += "#{tab(3)}<string>d</string>\n"
        result += plural_hash.map{|quantity,value| "#{tab(3)}<key>#{quantity}</key>\n#{tab(3)}<string>#{value}</string>"}.join("\n")
        result += "\n#{tab(2)}</dict>\n"

        result += "#{tab(1)}</dict>\n"
      end

      def format_comment(definition, lang)
        "<!-- #{definition.comment.gsub('--', '—')} -->\n" if definition.comment
      end

      def read(io, lang)
        result = Plist.parse_xml(io)
        if result
         result.each { |el|
            key = ""
            plurals_hash = Hash.new

            el.each { |n| 
              if n.kind_of? String
                key = n
              else n.kind_of? Hash
                n.collect {|key,value| 
                  if key != "NSStringLocalizedFormatKey" 
                    value.collect {|key,value| 
                      if key != "NSStringFormatSpecTypeKey" && key != "NSStringFormatValueTypeKey"
                        plurals_hash[key] = value 
                      end
                    }
                  end
                }
              end
           }
           if key != "" 
              set_plural_translation_for_key(key, lang, plurals_hash)
           end
         }           
        end
      end

      def tab(level)
        "\t" * level
      end

      def should_include_definition(definition, lang)
        return definition.is_plural? && definition.plural_translation_for_lang(lang)
      end
    end
  end
end

Twine::Formatters.formatters << Twine::Formatters::ApplePlural.new
