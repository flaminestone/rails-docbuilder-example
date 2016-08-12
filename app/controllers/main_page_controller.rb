class MainPageController < ApplicationController
  def index
  end

  def upload
    if !params[:uploadedFile].nil?
      uploaded_io = params[:uploadedFile]
      File.open(Rails.root.join('public', 'uploads', uploaded_io.original_filename), 'wb') do |file|
        file.write(uploaded_io.read)
      end
      file_data_hash = change_output_file(uploaded_io.original_filename)
      build(file_data_hash[:temp_script_file])
      unless params['uploadedFile'].nil?
        send_file(file_data_hash[:temp_output_file])
      end
    else
      flash[:notice] = "Error"
      render :action => :index
    end
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

  def edit_sample_file(script_file)
    script_file_content = File.open(script_file, "r").read
    format = script_file_content.match(/builder.SaveFile\(\"(.*)\"\)\;/)[1].split('"').first
    temp_output_file = Tempfile.new([File.basename(script_file), ".#{format}"])
    script_file_content.gsub!(/^builder\.SaveFile.*$/, "builder.SaveFile(\"#{format}\", \"#{temp_output_file.path}\");")
    script_file_content.sub!("{company}", params['input_company'])
    script_file_content.sub!("{name}", params['input_name'])
    script_file_content.sub!("{position}", params['input_position'])
    script_file_content.sub!("{cur_date_time}", "#{Time.now.day} ")
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
end
