namespace :charity do

  # bundle exec rake charity:import_all
  # bundle exec rake charity:import_all verbose=false
  # bundle exec rake charity:import_all verbose=false skip_download=true
  desc 'Download xls from irs and import charities'
  task :import_all => :environment do
    # Log what workbook, what download is in progress, successful imports
    verbose = (ENV['verbose'].present? && ENV['verbose'] == 'true')
    # Log every record read from the worksheets
    extremely_verbose = (ENV['extremely_verbose'].present? && ENV['extremely_verbose'] == 'true')
    # Look in the charity folder for xls and try to import them
    skip_download = (ENV['skip_download'].present? && ENV['skip_download'] == 'true')
    verbose = true if extremely_verbose

    CharityImporter.run(verbose, extremely_verbose, skip_download)
  end

  # bundle exec rake charity:import_xls xls_name=eo_xx.xls
  desc 'Import a single xls'
  task :import_xls => :environment do
    xls_name = ENV['xls_name']
    skip_download = (ENV['skip_download'].present? && ENV['skip_download'] == 'true')
    raise ArgumentError, 'Must specify xls_name' if xls_name.nil?
    CharityImporter.import_single_file(xls_name, skip_download)
  end
 end
