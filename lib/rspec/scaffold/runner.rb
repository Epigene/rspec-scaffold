module RSpec
  module Scaffold
    class Runner
      # this class serves as a wrapper for Generator class in that it handles receiving files as input.

      attr_reader :file

      # @param [Pathname] file
      def initialize(file = nil)
        @file = Pathname.new(file) if file
      end

      # @param [Symbol] mode
      def perform(mode=:to_file)
        fail ArgumentError, %Q(File or directory does not exist: "#{file}") if !File.exists?(file) && !File.exists?("#{file}.rb")

        ruby_files.each do |ruby_file|
          case mode
          when :to_file
            produce_scaffold_file(ruby_file)
          else # for :to_text and as a safe fallback
            produce_stdout_output(ruby_file)
          end
        end

        return true
      end

      def generate_spec(ruby)
        ryan = Ryan.new(ruby)
        if ryan.funcs.any?
          spec = RSpec::Scaffold::Generator.new
          spec.perform ryan
        else
          log "- #{truncate(ruby)} - no methods", :gray
          nil
        end
      rescue => e
        log "! #{truncate(ruby)} - #{e.inspect.gsub /^#<|>$/, ''}\n#{e.backtrace.take(10)}", :red
      end

      #
      # Private
      #

      def truncate(str)
        str.to_s.scan(/.+/).take(2).tap { |x| x[1..-1].each { |i| i[0..-1] = '...' } }.join
      end

      private

        def produce_scaffold_file(ruby_file)
          rspec_file = Pathname.new(spec_file(ruby_file))
          spec_file_path = rspec_file.to_s[%r|/(spec/.+)|, 1]
          next if rspec_file.exist?.tap { |exists| log "- #{spec_file_path} - already exists", :gray if exists }
          spec = generate_spec(Pathname.new(File.expand_path(ruby_file)))
          next unless spec

          # return nil if rspec_file.exist?.tap { |exists| log("- #{spec_file_path} - already exists", :gray) if exists }
          #
          # spec = generate_spec(ruby_file)
          # return nil if spec.size == 0

          log "+ #{spec_file_path}"
          FileUtils.mkdir_p(rspec_file.parent)
          File.open(rspec_file, 'wb') do |f|
            f << spec.join("\n")
          end
        end

        def produce_stdout_output(ruby_file)
          rspec_file = Pathname.new(spec_file(ruby_file))
          spec_file_path = rspec_file.to_s[%r|/(spec/.+)|, 1]
          spec = generate_spec(ruby_file)

          return nil if spec.size == 0

          log "=== #{spec_file_path} ==="
          puts spec.join("\n")
          log "========================="

          return true
        end

        def generate_spec(ruby_file)
          spec = RSpec::Scaffold::Generator.new Pathname.new(File.expand_path(ruby_file))
          if spec.funcs.any?
            spec.perform
          else
            log "- #{ruby_file} - no methods", :gray
            []
          end
        rescue => e
          log "! #{ruby_file} - #{e.inspect.gsub /^#<|>$/, ''}", :red
          return []
        end

        def ruby_files
          if File.directory?(file)
            Dir[File.join(file, '**', '*.rb')]
          else
            if file.extname.empty?
              ["#{file}.rb"]
            else
              [file]
            end
          end
        end

        # @note subbing out /app/ is Rails specific
        def spec_file(ruby_file)
          File.join(spec_path, "#{specify(ruby_file)}").sub '/app/', '/'
        end

        def specify(file_name)
          return Pathname.new(file_name.to_s.gsub(%r'.rb\z', '_spec.rb'))
        end

        def spec_path
          if File.directory?(File.expand_path('spec'))
            File.expand_path('spec')
          else
            fail "Couldn't find spec directory"
          end
        end

        def log(msg = nil, color = :green)
          HighLine.new.say %Q(  <%= color('#{msg}', :#{color}) %>)
        end

    end
  end
end
