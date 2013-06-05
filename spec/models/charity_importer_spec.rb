require 'spec_helper'


describe CharityImporter do

  describe "read_excel" do
    it "should raise if file not found" do
      file = 'asdf.not'
      File.exists?(CharityImporter.send(:charity_excel_dir) + file).
      should == false
      expect {CharityImporter.send(:read_excel,file)}.to raise_error(ArgumentError)
    end

  end # end read_excel

  describe "run" do
    it "should allow skipping downloads" do
      CharityImporter.should_not_recieve(:get_irs_page)
      CharityImporter.should_receive(:files_from_dir).once {['file.xls']}
      CharityImporter.should_receive(:read_excel).once
      CharityImporter.run(true, true, true)
    end

  end # end run

end
