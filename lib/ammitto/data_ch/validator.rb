# frozen_string_literal: true

require 'yaml'
require 'json'
require 'json-schema'
require 'fileutils'

module Ammitto
  module DataCh
    # Validates Switzerland source YAML files against JSON schemas
    class Validator
      attr_reader :schemas_dir, :errors

      def initialize(schemas_dir = nil)
        @schemas_dir = schemas_dir || default_schemas_dir
        @errors = []
      end

      def validate(file_path)
        @errors = []

        unless File.exist?(file_path)
          @errors << { path: file_path, message: "File not found" }
          return false
        end

        data = load_yaml(file_path)
        return false if data.nil?

        schema_type = determine_schema_type(file_path, data)
        return false if schema_type.nil?

        schema = load_schema(schema_type)
        return false if schema.nil?

        validate_against_schema(data, schema, file_path)
      end

      def validate_all(sources_dir = nil)
        sources_dir ||= File.join(File.dirname(@schemas_dir), 'sources')
        report = {
          total_files: 0,
          valid_files: 0,
          invalid_files: 0,
          errors: []
        }

        yaml_files = Dir.glob(File.join(sources_dir, '**', '*.yml')) +
                      Dir.glob(File.join(sources_dir, '**', '*.yaml'))

        yaml_files.each do |file|
          report[:total_files] += 1
          if validate(file)
            report[:valid_files] += 1
          else
            report[:invalid_files] += 1
            report[:errors] << { file: file, errors: @errors.dup }
          end
        end

        report
      end

      private

      def default_schemas_dir
        File.join(File.dirname(__dir__), '..', '..', 'schemas')
      end

      def load_yaml(file_path)
        YAML.safe_load_file(file_path, permitted_classes: [Date, Time], aliases: true)
      rescue Psych::SyntaxError => e
        @errors << { path: file_path, message: "YAML syntax error: #{e.message}" }
        nil
      end

      def determine_schema_type(file_path, data)
        if file_path.include?('sanction-lists')
          'ch-announcement'
        elsif file_path.include?('legal-instruments')
          'ch-legal-instrument'
        elsif file_path.include?('supporting/document-types')
          'document-types'
        elsif file_path.include?('supporting/organizations')
          'organizations'
        elsif data.key?('sanction_details')
          'ch-announcement'
        elsif data.key?('type') && %w[act ordinance decision regulation].include?(data['type'])
          'ch-legal-instrument'
        else
          @errors << { path: file_path, message: "Cannot determine schema type" }
          nil
        end
      end

      def load_schema(schema_type)
        schema_file = File.join(@schemas_dir, "#{schema_type}.yml")
        unless File.exist?(schema_file)
          @errors << { message: "Schema not found: #{schema_type}" }
          return nil
        end

        YAML.safe_load_file(schema_file, permitted_classes: [Date, Time])
      rescue StandardError => e
        @errors << { message: "Failed to load schema #{schema_type}: #{e.message}" }
        nil
      end

      def validate_against_schema(data, schema, file_path)
        begin
          JSON::Validator.validate!(schema, data)
          true
        rescue JSON::Schema::ValidationError => e
          @errors << { path: file_path, message: e.message }
          false
        rescue JSON::Schema::SchemaError => e
          @errors << { path: file_path, message: "Schema error: #{e.message}" }
          false
        end
      end
    end
  end
end
