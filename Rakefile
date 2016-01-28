require 'bundler/gem_tasks'
require 'rake/testtask'
require 'date'

Rake::TestTask.new do |t|
    t.libs << 'test'
    t.test_files = FileList['test/**/*_test.rb']
    t.verbose = true
end

Rake::TestTask.new do |t|
  t.name = :bisect
  t.libs << 'test'
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = true
end

desc 'Run tests'
task :default => :test

desc 'Run and log performance benchmarks'
task :benchmark do
  begin
    target = File.join('benchmark','benchmark.log')
    file   = File.open(target, 'a')
    result = %x(benchmark/benchmark.rb)
    puts result
    file.puts DateTime.now.strftime('%F')
    file.puts '-'*10
    file.puts result
    file.puts "\n"
  ensure
    file.close
  end
end
