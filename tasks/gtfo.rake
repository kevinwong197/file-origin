require 'fileutils'
require 'rake/clean'
require 'zip'

task default: ['build']

desc 'Build release'
task :build => ['build_zip']

desc 'clear target folder'
task :clean do
  Rake::Cleaner.cleanup_files(FileList['target/**/*'])
  Dir.mkdir 'target' unless File.directory? 'target'
end

desc 'create folder using ocra'
task :ocra_folder => ['clean'] do
  sh 'ocra bin/gtfo.rb lib/ --gem-minimal --output target/release.exe --no-lzma --debug-extract'
  sh 'target/release.exe'
  Dir['target/ocr*.tmp'].each do |d|
    if Dir["#{d}/*"].empty?
      FileUtils.remove_dir(d)
    end
  end
  File.rename Dir['target/ocr*.tmp'].first, 'target/release'
end

desc 'add files to release folder'
task :add_files => ['ocra_folder'] do
  Dir['res/*'].each do |d|
    IO.copy_stream(d, "target/release/#{File.basename(d)}")
  end
end

desc 'build as dir'
task :build_dir => ['add_files']

desc 'package into zip'
task :build_zip => ['build_dir'] do
  dir = File.expand_path 'target/release/'
  zipname = File.expand_path 'target/release.zip'

  Zip::File.open(zipname, Zip::File::CREATE) do |zipfile|
    Dir[File.join(dir, '**', '*')].each do |file|
      node = File.join('gtfo', file.sub(dir, ''))
      zipfile.add(node, file)
    end
  end
end