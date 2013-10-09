#require 'poi' # http://poi.apache.org/
require 'nokogiri'
require 'typhoeus'
require 'spreadsheet'

module CharityImport
  class Importer
    EXCEL_DIRECTORY = 'tmp/charity_excel_files'
    IRS_URL = 'http://www.irs.gov/pub/irs-soi/'
    LINK_REGEX = /eo_[^.]{2,4}.xls/

    # The charities we pull from irs.gov are *all* charities. Not all of these are eligible. As a rule of thumb,
    # we want to only include 501(c)(3)s -- these are designated by a 'deductibility' code of 1 in the IRS excel
    # files. I think we want to exclude those with a 'Foundation Code' -- these are foundations and trusts run by
    # schools, some  churches and some governmental entities.
    DESIRED_DEDUCTION_CODE = '1.0'
    DESIRED_FOUNDATION_CODE = '0.0'
    DESIRED_EXEMPT_CODE = '1.0'

    @@verbose = true
    @@verbose_with_misses = false

    class << self
      def run(verbose = true, with_misses = false, skip_downloading = false)
        @@verbose = verbose
        @@verbose_with_misses = with_misses
        files = nil

        collect_charities_ein = collect_charities

        if skip_downloading
          files = files_from_dir
        else
          files = select_eo_links(get_irs_page)
          create_excel_dir_if_needed
          files.each { |file| download_eo_file(file) }
        end

        files.each do |file|
          total_left_charities = read_excel(file, collect_charities_ein)
          collect_charities_ein = total_left_charities
        end

        if collect_charities_ein.size > 0
          update_charities(collect_charities_ein)
        end

      end

      def import_single_file(file_name, skip_downloading = true)
        collect_charities_ein = collect_charities

        if !skip_downloading
          create_excel_dir_if_needed
          download_eo_file(file_name)
        end

        total_left_charities = read_excel(file_name, collect_charities_ein)

        if total_left_charities.size > 0
          update_charities(total_left_charities)
        end

      end

      def collect_charities
        # why are we loading all charities here?
        # we shouldn't keep all of the charities in memory
        # we should not be excluding charities regardlesscd
        charities_date = Charity.all
        collect_charities_ein = []
        charities_date.each do |charity|
          collect_charities_ein << charity.ein
        end
        return collect_charities_ein
      end

      def update_charities(collect_charities_ein)
        collect_charities_ein.each do |a|
          charity = Charity.find_by_ein(a)
          charity.update_attribute :status, "inactive"
          puts "EIN:#{charity.ein} Has been inactive"
        end
      end

      def add_email_charity(charity_id, charity_email)
        charity = Charity.find(charity_id)
        charity.update_attributes(:email => charity_email)
      end

    private

      def get_irs_page
        puts "Loading #{IRS_URL}" if @@verbose
        Nokogiri::HTML(Typhoeus.get(IRS_URL).body)
      end

      # find the links that match our regex
      def select_eo_links(irs_doc)
        irs_doc.xpath('//a/@href').select { |link| link.to_s =~ LINK_REGEX }.map(&:to_s)
      end

      def charity_excel_dir
        Rails.root.join(EXCEL_DIRECTORY)
      end

      def files_from_dir
        Dir.entries(charity_excel_dir).select{ |m| m =~ /\.xls/ }
      end

      def create_excel_dir_if_needed
        FileUtils.mkdir_p(charity_excel_dir) if !File.exists?(charity_excel_dir)
      end

      def write_file(file_name, content)
        File.open(file_name, 'wb') { |file| file.write(content) }
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

      def tag_charity(charity)
        tags = get_all_tags(charity)
        puts "Got all the tags: #{tags}"
        tags.each do |name|
          tag = Tag.find_or_create_by_name(name)
          begin
            tag.charities << charity
            tag.save
          rescue ActiveRecord::RecordNotUnique => e
            # just leave it if it already eixsts.
          end
        end
      end

      def get_all_tags(charity)
        tag_names = []
        tag_names << classification_tag_name(charity.subsection_code, charity.classification_code)
        tag_names << activity_tag_names(charity.activity_code)
        tag_names << ntee_common_tag_name(charity.ntee_code)
        tag_names << ntee_core_tag_name(charity.ntee_code)
        tag_names.flatten.compact
      end

      def classifications
        CharityImport::Classification::CLASSIFICATION
      end

      def classification_tag_name(subsection_code, classification_code)
        classifications[subsection_code.to_i.to_s] && classifications[subsection_code.to_i.to_s][classification_code.to_i.to_s]
      end

      def activities
        CharityImport::Classification::ACTIVITY
      end

      def activity_tag_names(code)
        return nil if code.blank? || code == '0.0'

        code = code.to_i.to_s
        while code.length < 9 do
          code = code.prepend('0')
        end

        [activity_tag_name(code[0..2]),
         activity_tag_name(code[3..5]),
         activity_tag_name(code[6..8])]
      end

      def activity_tag_name(code)
        activities[code]
      end

      def ntee_common_codes
        CharityImport::Classification::NTEE_COMMON_CODES
      end

      def ntee_common_tag_name(ntee_code)
         ntee_common_codes[ntee_code.first] if ntee_code.present?
      end

      def ntee_core_codes
        CharityImport::Classification::NTEE_CORE_CODES
      end

      def ntee_core_tag_name(ntee_code)
        ntee_core_codes[ntee_code] if ntee_code.present?
      end

      def read_excel(file, collect_charities_ein)
        file_with_dir = charity_excel_dir + file
        raise ArgumentError, "File not found: #{file_with_dir}" if !File.exists?(file_with_dir)
        puts "Reading spreadsheet: #{file}" if @@verbose
        book = Spreadsheet.open(file_with_dir)
#        book = POI::Workbook.open(file_with_dir)
        sheet = book.worksheet(0)
#        sheet = book.worksheets[0] # use the first sheet
        rows = sheet.rows
        rows.each_with_index do |row, i|
          next if i == 0 # first row is headings

          ein = row[0].to_s.strip
          name = row[1].to_s.strip
			    deduction_code = row[12].to_s.strip
			    foundation_code = row[13].to_s.strip
          exemption_code = row[16].to_s.strip

			    puts "EIN:#{ein} Name:#{name} Deduction Code:#{deduction_code} Foundation Code:#{foundation_code}" if @@verbose_with_misses
          # we should not be deleting this charity. it might need to be updated

          collect_charities_ein.delete_if {|x| x == ein.to_i }

          next if deduction_code != DESIRED_DEDUCTION_CODE
          next if foundation_code != DESIRED_FOUNDATION_CODE
          next if exemption_code != DESIRED_EXEMPT_CODE

          options = { :ein => ein,
			                :name => name,
			                :address => row[3].to_s.strip,
			                :city => row[4].to_s.strip,
			                :state => row[5].to_s.strip,
			                :zip => row[6].to_s.strip,
			                :ntee_code => row[30].to_s.strip,
			                :subsection_code => row[8].to_s.strip,
			                :classification_code => row[10].to_s.strip,
			                :activity_code => row[14].to_s.strip,
                      :status => 'active'
                    }

			    puts "---Creating Charity with #{options.inspect}" if @@verbose
          charity = Charity.create_or_update(options)
          tag_charity(charity)
        end
        return collect_charities_ein
      end # end read_excel
    end # end self
  end
end
