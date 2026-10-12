# frozen_string_literal: true

desc 'Validate source YAML files against schemas'
task :validate do
  ammitto_path = File.expand_path('../ammitto/lib', __dir__)
  $LOAD_PATH.unshift(ammitto_path) if Dir.exist?(ammitto_path)

  require_relative 'lib/ammitto/data_ch/validator'

  sources_dir = File.expand_path('sources', __dir__)
  validator = Ammitto::DataCh::Validator.new

  puts "Validating YAML files in #{sources_dir}..."
  puts '-' * 50

  report = validator.validate_all(sources_dir)

  puts "Total files: #{report[:total_files]}"
  puts "Valid files: #{report[:valid_files]}"
  puts "Invalid files: #{report[:invalid_files]}"
  puts

  if report[:invalid_files] > 0
    puts "Errors:"
    report[:errors].each do |error|
      puts "  #{error[:file]}"
      error[:errors].each do |e|
        puts "    - #{e[:message]}"
      end
    end
    exit 1
  else
    puts "All files are valid!"
  end
end
