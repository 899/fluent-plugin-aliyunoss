lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name    = "fluent-plugin-aliyunoss"
  spec.version = "0.2.4"
  spec.authors = ["junjie"]
  spec.email   = ["junjzh0205@gmail.com"]

  spec.description   = "Aliyun OSS output plugin for Fluentd event collector"
  spec.summary       = spec.description
  spec.homepage      = "https://github.com/899/fluent-plugin-aliyunoss"
  spec.license       = "Apache-2.0"

  test_files, files  = `git ls-files -z`.split("\x0").partition do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.files         = files
  spec.executables   = files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = test_files
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.14"
  spec.add_development_dependency "rake", "~> 12.0"
  spec.add_development_dependency "test-unit", "~> 3.0"
  spec.add_runtime_dependency "fluentd", [">= 0.14.10", "< 2"]
  spec.add_dependency "aliyun-sdk", [">= 0.6.0"]
end
