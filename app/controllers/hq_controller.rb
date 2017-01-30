class HqController < ApplicationController
  def dashboard

    @icoFolder = nil

    @section = "Home"

    @targeturl = "/"

    @targettext = "Logout"

    @user = User.find_by_username(session[:current_user_id])

    @districts = {}

    District.all.each do |district|

      @districts[district.id] = district.name

    end
  end

  def search

  end
  
  def print_preview
    @section = "Print Preview"
    @targeturl = "/hq/print_certificates" 
    @child = Person.find(params[:id])
    @available_printers = CONFIG["printer_name"].split('|')
    render :layout => "application"
  end
  
  def death_certificate_preview
   
    @person = Person.find(params[:id])
    
    @barcode = File.read("#{CONFIG['barcodes_path']}#{@person.id}.png") rescue nil
    
    if @barcode.nil?
      p = Process.fork{`bin/generate_barcode #{@person.npid} #{@person.id} #{CONFIG['barcodes_path']}`}
      Process.detach(p)
    end
    
    sleep(0.5)
    
    @barcode = File.read("#{CONFIG['barcodes_path']}#{@person.id}.png")
    
    render :layout => false, :template => 'hq/death_certificate'
    
  end
  
  def death_certificate
  
  end
  
  def death_certificate_print
    @person = Person.find(params[:id])
    
    if CONFIG['pre_printed_paper'] == true
       render :layout => false, :template => 'hq/death_certificate_print'
    else
       render :layout => false 
    end
  
  end
  
  def do_print_these
     
    selected = params[:selected].split("|")

    paper_size = GlobalProperty.find("paper_size").value rescue "A4"
    
    if paper_size == "A4"
       zoom = 0.83
    elsif paper_size == "A5"
       zoom = 0.6
    end
     
    selected.each do |key|

      person = Person.find(key.strip)

      next if person.blank?
      
      person.update_attributes(:record_status => "PRINTED",
                               :request_status => "CLOSED", 
                               :printed_at => Time.now,
                               :date_certificate_issued => Date.today.strftime("%Y-%m-%d") ) if person.record_status != 'PRINTED'
      
     
      id = person.id
      
      print_url = "wkhtmltopdf --zoom #{zoom} --page-size #{paper_size} --username #{CONFIG["print_user"]} --password #{CONFIG["print_password"]} #{CONFIG["protocol"]}://#{request.env["SERVER_NAME"]}:#{request.env["SERVER_PORT"]}/death_certificate/#{id} #{CONFIG['certificates_path']}#{id}.pdf\n"    
      
      t4 = Thread.new {

        Kernel.system print_url

        sleep(4)

        Kernel.system "lp -d #{params[:printer_name]} #{CONFIG['certificates_path']}#{id}.pdf\n"

        sleep(5)
        
      }

      sleep(1)

    end
    
   # redirect_to "/hq/print_certificates_datatable" and return
  
  end
  
  def print_certificates
  
  end
  
end