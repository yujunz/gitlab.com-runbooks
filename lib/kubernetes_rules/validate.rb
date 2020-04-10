#!/usr/bin/env ruby
# frozen_string_literal: true

module KubernetesRules
  # Validate confirms both the yaml and rules are legit
  class Validate
    def initialize
      @output_dir = './rules-k8s'
    end

    def validate!
      files = Dir.glob("#{@output_dir}/*.yml")

      if files.empty?
        puts "No file exist to validate in #{@output_dir}".red
        exit 1
      end

      abort "\nOne or more files failed validation!".red unless yaml_files_valid?(files)
    end

    def yaml_valid?(file)
      puts "Validating YAML on #{file}"
      begin
        YAML.load_file(file)
      rescue StandardError => e
        puts "Validation Failed on #{file}:\n#{e}".red
        return false
      end

      true
    end

    def rules_valid?(file)
      puts "Validating Rule(s) on #{file}"
      error_count = 0
      begin
        render = YAML.load_file(file)
      rescue StandardError
        puts "Skipping Rule Validation on #{file} due to improper yaml".yellow
        return true
      end
      render['spec']['groups'].each do |group|
        group['rules'].each do |rule|
          rule.each do |k, v|
            if k == 'labels'
              v.each do |j, w|
                unless w.is_a?(String)
                  puts "`#{j}: #{w}` is the incorrect type, must be string".red
                  error_count += 1
                end
              end
            end
            next if k == 'labels'
            next if k == 'annotations'

            unless v.is_a?(String)
              puts "#{k}: #{v} is the incorrect type, must be string".red
              error_count += 1
            end
          end
        end
      end

      error_count.zero?
    end

    def yaml_files_valid?(files)
      valid = true
      files.each do |file|
        unless yaml_valid?(file)
          puts "File #{file} did not pass YAML validation"
          valid = false
        end
        unless rules_valid?(file)
          puts "File #{file} did not pass rule validation"
          valid = false
        end
      end
      valid
    end
  end
end
