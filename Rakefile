# frozen_string_literal: true

require 'fileutils'

desc 'Clean generated API files (JSON-LD, search index, stats)'
task :clean do
  api_dir = File.expand_path('api', __dir__)

  if Dir.exist?(api_dir)
    patterns = [
      File.join(api_dir, 'node', '**', '*.jsonld'),
      File.join(api_dir, '*.jsonld'),
      File.join(api_dir, '*.json'),
      File.join(api_dir, '*.ttl')
    ]

    removed_count = 0
    patterns.each do |pattern|
      Dir.glob(pattern).each do |file|
        File.delete(file)
        removed_count += 1
      end
    end

    # Remove empty directories
    Dir.glob(File.join(api_dir, '**', '*')).select { |d| Dir.exist?(d) }.each do |dir|
      Dir.rmdir(dir) if Dir.empty?(dir)
    rescue SystemCallError
      # Directory not empty, ignore
    end

    puts "Cleaned #{removed_count} generated files from api/"
  else
    puts 'No api/ directory to clean'
  end
end

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

desc 'Generate API files from source YAML data'
task :generate do
  ammitto_path = File.expand_path('../ammitto/lib', __dir__)
  $LOAD_PATH.unshift(ammitto_path) if Dir.exist?(ammitto_path)

  require 'ammitto'
  require 'ammitto/config/defaults'
  require 'ammitto/cli/harmonize_command'

  sources_dir = File.expand_path('..', __dir__)
  output_dir = File.expand_path('api', __dir__)

  puts "Generating API files from sources..."
  puts "Sources dir: #{sources_dir}"
  puts "Output dir: #{output_dir}"
  puts '-' * 50

  options = {
    sources_dir: sources_dir,
    output_dir: output_dir,
    verbose: ENV['VERBOSE'] == 'true'
  }

  command = Ammitto::Cmd::HarmonizeCommand.new(options, [:ch])
  command.run

  puts '-' * 50
  puts 'Generation complete!'
end

desc 'Validate and generate in one step'
task build: [:validate, :generate]

desc 'Clean and regenerate all API files'
task regenerate: [:clean, :generate]

task default: :generate
