require 'nokogiri'
require 'typhoeus'
require 'csv'

module CharityImport
  class Importer
    CSV_DIRECTORY = 'tmp/charity_csv_files'
    IRS_URL = 'https://www.irs.gov/pub/irs-soi/'
    LINK_REGEX = /eo_[^.]{2}.csv/

    DESIRED_DEDUCTION_CODES = ['1']
    DESIRED_FOUNDATION_CODES = ['0','2','3','9','10','11','12','13','14','15','16']

    @@verbose = true
    @@verbose_with_misses = true

    class << self

      def run(verbose = true, with_misses = false, skip_download = false)
        @@verbose = verbose
        @@verbose_with_misses = with_misses
        files = nil

        if skip_download
          files = files_from_dir
        else

          files = select_eo_links(get_irs_page)
          create_csv_dir_if_needed
          files.each { |file| download_eo_file(file) }
        end

        files.each { |file| read_csv(file) }
      end

      def import_single_file(file_name, skip_download = true)

        if !skip_download
          create_csv_dir_if_needed
          download_eo_file(file_name)
        end
        read_csv(file_name)
      end

      def add_email_charity(charity_id, charity_email)
        charity = Charity.find(charity_id)
        charity.update_attributes(:email => charity_email)
      end

    private

      def get_irs_page
        Nokogiri::HTML(Typhoeus.get(IRS_URL).body)
      end

      # find the links that match our regex
      def select_eo_links(irs_doc)
        irs_doc.xpath('//a/@href').select { |link| link.to_s =~ LINK_REGEX }.map(&:to_s)
      end

      def charity_csv_dir
        Rails.root.join(CSV_DIRECTORY)
      end

      def files_from_dir
        Dir.entries(charity_csv_dir).select{ |m| m =~ /\.csv/ }
      end

      def create_csv_dir_if_needed
        FileUtils.mkdir_p(charity_csv_dir) if !File.exists?(charity_csv_dir)
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
          write_file(charity_csv_dir + file, response.body)
        end
        request.run
      end

      def tag_charity(charity)
        tags = get_all_tags(charity)
        puts "Got all the tags: #{tags}" if @@verbose_with_misses
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

      def activity_tag_name(code)
        activities[code]
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

      def read_csv(file)
        file_with_dir = charity_csv_dir + file
        raise ArgumentError, "File not found: #{file_with_dir}" if !File.exists?(file_with_dir)

        puts "Reading CSV: #{file}" if @@verbose

        CSV.foreach(file_with_dir, row_sep: :auto, headers: true) do |row|
          ein = row[0].to_s.strip
          next if ein.empty?

          name = row[1].to_s.strip
          deductibility_code = row[12].to_s.strip
          foundation_code = row[13].to_s.strip

          puts "EIN:#{ein} Name:#{name} Deduction Code:#{deductibility_code} Foundation Code:#{foundation_code}" if @@verbose_with_misses

          if ((DESIRED_DEDUCTION_CODES.include?(deductibility_code)) && (DESIRED_FOUNDATION_CODES.include?(foundation_code)))
              active = 'true'
          else
              active = 'false'
          end

          ruling_date = row[11].to_s.strip
          if ruling_date.length==6 && ruling_date.to_i!=0 && ruling_date != '190900'
            ruling_date = Date.strptime(ruling_date, "%Y%m")
          else
            ruling_date = nil
          end

          tax_period = row[17].to_s.strip
          if tax_period.length==6 && tax_period.to_i!=0 && tax_period != '190900'
            tax_period = Date.strptime(tax_period, "%Y%m")
          else
            tax_period = nil
          end

          charity_options = {
            :ein => ein,
            :name => name.titleize,
            :care_of => row[2].to_s.strip,
            :address => row[3].to_s.strip,
            :city => row[4].to_s.strip.titleize,
            :state => row[5].to_s.strip,
            :zip => row[6].to_s.strip,
            :group_code => row[7].to_s.strip,
            :subsection_code => row[8].to_s.strip,
            :affiliation_code => row[9].to_s.strip,
            :classification_code => row[10].to_s.strip,
            :ruling_date => ruling_date,
            :deductibility_code => deductibility_code,
            :foundation_code => foundation_code,
            :activity_code => row[14].to_s.strip,
            :organization_code => row[15].to_s.strip,
            :status_code => row[16].to_s.strip,
            :tax_period => tax_period,
            :asset_code => row[18].to_s.strip,
            :income_code => row[19].to_s.strip,
            :filing_requirement_code => row[20].to_s.strip,
            :pf_filing_requirement_code => row[21].to_s.strip,
            :accounting_period => row[22].to_s.strip,
            :asset_amount => row[23].to_i,
            :income_amount => row[24].to_i,
            :revenue_amount => row[25].to_s.strip,
            :ntee_code => row[26].to_s.strip,
            :secondary_name => row[27].to_s.strip.titleize,
            :active => active
          }

          puts "---Creating Charity with #{charity_options.inspect}" if @@verbose_with_misses

          charity = Charity.find_or_initialize_by(ein: ein)
          begin
            charity.update(charity_options)
            tag_charity(charity)
            rescue Exception => e
            if e.is_a? ActiveRecord::RecordNotUnique
              Rails.logger.warn(e)
            end
          end

        end # end CSV.foreach
      end # end read_csv
    end # end self
  end
end
