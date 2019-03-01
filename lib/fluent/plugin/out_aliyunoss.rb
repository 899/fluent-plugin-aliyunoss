#
# Copyright 2019- junjie
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "fluent/plugin/output"
require 'fluent/log'
require 'aliyun/oss'
require 'zlib'
require 'time'
require 'tempfile'
require 'securerandom'
require 'socket'

module Fluent
	module Plugin
		class AliyunossOutput < Fluent::Plugin::Output
			Fluent::Plugin.register_output("aliyunoss", self)

			helpers :formatter, :inject, :compat_parameters

			DEFAULT_FORMAT_TYPE = "out_file"
			DEFAULT_TIMEKEY = 60 * 60 * 24

			desc "OSS access key id"
			config_param :oss_key_id, :string
			desc "OSS access key secret"
			config_param :oss_key_secret, :string, secret: true
			desc "OSS bucket name"
			config_param :oss_bucket, :string
			desc "OSS endpoint"
			config_param :oss_endpoint, :string
			desc "The format of OSS object keys path"
			config_param :oss_path, :string, default: "${tag}/date=%Y-%m-%d/%{host}-worker#{ENV['SERVERENGINE_WORKER_ID']}-%{uuid}-%Y%m%d%H%M%S"
			desc "Archive format on OSS"
			config_param :store_as, :string, default: "gz"

			config_section :format do
				config_set_default :@type, DEFAULT_FORMAT_TYPE
			end

			config_section :buffer do
				config_set_default :chunk_keys, ['time']
				config_set_default :timekey, DEFAULT_TIMEKEY
			end

			def configure(conf)
				super
				compat_parameters_convert(conf, :formatter, :buffer, :inject, default_chunk_key: "time")

				@json_formatter = formatter_create(usage: 'formatter_in_example_json', type: 'json')
			end

			def compress(chunk, tmp)
				if @store_as == "orc"
					# We just need a tmp file path, orc-tools convert won't work if file exists
					output_path = tmp.path
					tmp.delete
					# Create a symlink with .json suffix, to fool orc-tools
					chunk_path = File::realpath(chunk.path)
					fake_path = "#{chunk_path}.json"
					File::symlink(chunk_path, fake_path)

					command = "java -Dlog4j.configuration=file:/log4j.properties -jar /orc-tools.jar convert -o #{output_path} #{fake_path}"
					res = system command
					unless res
						raise "failed to execute java -jar /orc-tools.jar command. status = #{$?}"
					end
					File::unlink(fake_path)
				else
					res = system "gzip -c #{chunk.path} > #{tmp.path}"
					unless res
						log.warn "failed to execute gzip command. Fallback to GzipWriter. status = #{$?}"
						begin
							tmp.truncate(0)
							gw = Zlib::GzipWriter.new(tmp)
							chunk.write_to(gw)
							gw.close
						ensure
							gw.close rescue nil
						end
					end
				end
			end

			def process_object_key_format(chunk, key_format)
				key_map = {
					host: Socket.gethostname,
					uuid: SecureRandom.hex(4),
				}
				result = key_format
				key_map.each do |k, v|
					result = result.gsub("%{#{k.to_s}}", v)
				end
				extract_placeholders(result, chunk.metadata)
			end

			def multi_workers_ready?
				true
			end

			def start
				super
				@client = Aliyun::OSS::Client.new(
					:endpoint => @oss_endpoint,
					:access_key_id => @oss_key_id,
					:access_key_secret => @oss_key_secret)

				raise "Specific bucket not exists: #{@oss_bucket}" unless @client.bucket_exists? @oss_bucket

				@bucket = @client.get_bucket(@oss_bucket)
			end

			def format(tag, time, record)
				r = inject_values_to_record(tag, time, record)
				@json_formatter.format(tag, time, r)
			end

			def write(chunk)
				begin
					f = Tempfile.new('oss-')
					output_path = f.path
					compress(chunk, f)
					path = process_object_key_format(chunk, "#{@oss_path}.#{@store_as}")
					raise "Upload #{output_path} failed" unless @bucket.resumable_upload(path, output_path)
				ensure
					f.close(true)
				end
			end
		end
	end
end