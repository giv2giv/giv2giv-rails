require 'poi' # http://poi.apache.org/
require 'nokogiri'
require 'typhoeus'


class CharityImporter
  EXCEL_DIRECTORY = 'tmp/charity_excel_files'
  IRS_URL = 'http://www.irs.gov/pub/irs-soi/'
  LINK_REGEX = /eo_[^.]{2,4}.xls/

  # The charities we pull from irs.gov are *all* charities. Not all of these are eligible. As a rule of thumb,
  # we want to only include 501(c)(3)s -- these are designated by a 'deductibility' code of 1 in the IRS excel
  # files. I think we want to exclude those with a 'Foundation Code' -- these are foundations and trusts run by
  # schools, some  churches and some governmental entities.
  DESIRED_DEDUCTION_CODE = '1.0'
  DESIRED_FOUNDATION_CODE = '0.0'

  @@verbose = true
  @@verbose_with_misses = false

  class << self
    def run(verbose = true, with_misses = false, skip_downloading = false)
      @@verbose = verbose
      @@verbose_with_misses = with_misses
      files = nil

      if skip_downloading
        files = files_from_dir
      else
        files = select_eo_links(get_irs_page)
        create_excel_dir_if_needed
        files.each {|file| download_eo_file(file)}
      end

      files.each {|file| read_excel(file)}
    end

    def import_single_file(file_name)
      read_excel(file_name)
    end

  private

    def get_irs_page
      puts "Loading #{IRS_URL}" if @@verbose
      Nokogiri::HTML(Typhoeus.get(IRS_URL).body)
    end

    # find the links that match our regex
    def select_eo_links(irs_doc)
      irs_doc.xpath('//a/@href').select {|link| link.to_s =~ LINK_REGEX}.map(&:to_s)
    end

    def charity_excel_dir
      Rails.root.join(EXCEL_DIRECTORY)
    end

    def files_from_dir
      Dir.entries(charity_excel_dir).select{|m| m =~ /\.xls/}
    end

    def create_excel_dir_if_needed
      Dir.mkdir(charity_excel_dir) if !File.exists?(charity_excel_dir)
    end

    def write_file(file_name, content)
      File.open(file_name, 'wb') {|file| file.write(content)}
    end

    # Using hydra(parallel requests) exhausts jvm heap(@ 4GB!) so download one at a time
    def download_eo_file(file)
      puts "Downloading #{file}..." if @@verbose
      request = Typhoeus::Request.new(IRS_URL + file)
      request.on_complete do |response|
        puts "-- #{file} download complete!" if @@verbose
        write_file(charity_excel_dir + file, response.body)
      end
      request.run
    end

    def read_excel(file)
      file_with_dir = charity_excel_dir + file
      raise ArgumentError, "File not found: #{file_with_dir}" if !File.exists?(file_with_dir)

      puts "Reading spreadsheet: #{file}" if @@verbose

      book = POI::Workbook.open(file_with_dir)
      sheet = book.worksheets[0] # use the first sheet
      rows = sheet.rows
      rows.each_with_index do |row, i|
        next if i == 0 # first row is headings

        ein = row[0].to_s.strip
        name = row[1].to_s.strip
			  deduction_code = row[12].to_s.strip
			  foundation_code = row[13].to_s.strip

			  puts "EIN:#{ein} Name:#{name} Deduction Code:#{deduction_code} Foundation Code:#{foundation_code}" if @@verbose_with_misses
			  next if deduction_code != DESIRED_DEDUCTION_CODE
        next if foundation_code != DESIRED_FOUNDATION_CODE

        options = {:ein => ein,
			             :name => name,
			             :address => row[3].to_s.strip,
			             :city => row[4].to_s.strip,
			             :state => row[5].to_s.strip,
			             :zip => row[6].to_s.strip,
			             :ntee_code => row[30].to_s.strip}

			  puts "---Creating Charity with #{options.inspect}" if @@verbose
        Charity.create_or_update(options)
      end
    end # end read_excel

  end # end self
end
