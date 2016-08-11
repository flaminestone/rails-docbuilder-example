class MainPageController < ApplicationController
  def index
  end

  def upload
    uploaded_io = params[:uploadedFile]
    File.open(Rails.root.join('public', 'uploads', uploaded_io.original_filename), 'wb') do |file|
      file.write(uploaded_io.read)
    end
    path_to_result_file = build_document(uploaded_io.original_filename)
    unless params['uploadedFile'].nil?
      send_file(path_to_result_file)
    end
  end

  def upload_data
    render text: params
  end
  private
  def build_document(file_path)
    file_data_hash = change_output_file(file_path)
    build(file_data_hash[:temp_script_file])
    file_data_hash[:temp_output_file]
  end

  def build(path)
    `documentbuilder #{path}`
  end

  def change_output_file(script_file)
    script_file_content = File.open("#{Rails.public_path}/uploads/#{script_file}", "r").read
    format = script_file_content.match(/builder.CreateFile\(\"(.*)\"\)\;/)[1]
    temp_output_file = Tempfile.new([File.basename(script_file), ".#{format}"])
    script_file_content.gsub!(/^builder\.SaveFile.*$/, "builder.SaveFile(\"#{format}\", \"#{temp_output_file.path}\");")
    temp_script_file = Tempfile.new([File.basename(script_file), File.extname(script_file)])
    temp_script_file.write(script_file_content)
    temp_script_file.close
    {temp_script_file: temp_script_file.path, temp_output_file: temp_output_file.path}
  end
end
