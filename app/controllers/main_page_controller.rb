require 'fileutils'
class MainPageController < ApplicationController
  def index
    @sample_code = get_sample_script_code
  end

  def load_and_build
    create_folder_if_not_exist(user_folder)
    file_name = Time.now.to_s.tr(' ','_')
    File.open("#{user_folder}/#{file_name}", 'wb') do |file|
      file.write(params['predefinedScript'])
    end
    file_data_hash = change_output_file("#{user_folder}/#{file_name}")
    build(file_data_hash[:temp_script_file])
    send_file(file_data_hash[:temp_output_file])
  end

  def upload
    create_folder_if_not_exist("#{Rails.public_path}/uploads/#{request.remote_ip}")
      uploaded_io = params[:uploadedFile]
      file_path = "#{user_folder}/#{uploaded_io.original_filename}"
      File.open(file_path, 'wb') do |file|
        file.write(uploaded_io.read)
      end
    @sample_code = File.open(file_path, 'r'){ |file| file.read }
    unless @sample_code.valid_encoding?
      @sample_code = get_sample_script_code
      flash[:notice] = 'Encoding is not valid'
    end
    render :index
  end

  def upload_data
    file_data_hash = edit_sample_file(file_names[params['commit']])
    build(file_data_hash[:temp_script_file])
    send_file(file_data_hash[:temp_output_file])
  end

  private
  def build(path)
    `documentbuilder #{path}`
  end

  def change_output_file(file_path)
    script_file_content = File.open(file_path, "r").read
    format = script_file_content.match(/builder.SaveFile\(\"(.*)\",/)[1]
    temp_output_file = Tempfile.new([File.basename(file_path), ".#{format}"])
    script_file_content.gsub!(/^builder\.SaveFile.*$/, "builder.SaveFile(\"#{format}\", \"#{temp_output_file.path}\");")
    temp_script_file = Tempfile.new([File.basename(file_path), File.extname(file_path)])
    temp_script_file.write(script_file_content)
    temp_script_file.close
    {temp_script_file: temp_script_file.path, temp_output_file: temp_output_file.path}
  end

  def edit_sample_file(script_file)
    script_file_content = File.open(script_file, "r").read
    format = script_file_content.match(/builder.SaveFile\(\"(.*)\"\)\;/)[1].split('"').first
    temp_output_file = Tempfile.new([File.basename(script_file), ".#{format}"])
    script_file_content.gsub!(/^builder\.SaveFile.*$/, "builder.SaveFile(\"#{format}\", \"#{temp_output_file.path}\");")
    script_file_content.sub!("{company}", params['input_company'])
    script_file_content.sub!("{name}", params['input_name'])
    script_file_content.sub!("{position}", params['input_position'])
    script_file_content.sub!("{cur_date_time}", "#{Time.now.strftime("%d.%m.%Y")} ")
    temp_script_file = Tempfile.new([File.basename(script_file), File.extname(script_file)])
    temp_script_file.write(script_file_content)
    temp_script_file.close
    {temp_script_file: temp_script_file.path, temp_output_file: temp_output_file.path}
  end

  def file_names
    {'docx' => "#{Rails.public_path}/assets/docx.docbuilder",
     'xlsx' => "#{Rails.public_path}/assets/xlsx.docbuilder",
     'pdf' => "#{Rails.public_path}/assets/pdf.docbuilder"}
  end

  def create_folder_if_not_exist(folder_path)
    unless File.directory?(folder_path)
      FileUtils.mkdir_p(folder_path)
    end
  end

  def user_folder
    "#{Rails.public_path}/uploads/#{request.remote_ip}"
  end

  def get_sample_script_code
    File.open("#{Rails.public_path}/assets/sample.docbuilder", 'r'){ |file| file.read }
  end
end
