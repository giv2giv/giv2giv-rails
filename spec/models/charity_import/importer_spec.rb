require 'spec_helper'


describe CharityImport::Importer do

  describe "read_excel" do
    it "should raise if file not found" do
      file = 'asdf.not'
      File.exists?(CharityImport::Importer.send(:charity_excel_dir) + file).
      should == false
      expect {CharityImport::Importer.send(:read_excel,file)}.to raise_error(ArgumentError)
    end

  end # end read_excel

  describe "run" do
    it "should allow skipping downloads" do
      CharityImport::Importer.should_not_receive(:get_irs_page)
      CharityImport::Importer.should_receive(:files_from_dir).once {['file.xls']}
      CharityImport::Importer.should_receive(:read_excel).once
      CharityImport::Importer.run(true, true, true)
    end

  end # end run

  describe "classification tags" do
    it "should get classification" do
      code = CharityImport::Importer.send(:classification_tag_name, '24', '1')
      code.should == 'Trust ERISA'
    end

    it "should get classification when floats" do
      code = CharityImport::Importer.send(:classification_tag_name, '24.0', '1.0')
      code.should == 'Trust ERISA'
    end

    it "should be ok if subsection not found" do
      code = CharityImport::Importer.send(:classification_tag_name, nil, '1')
      code.should be_nil
    end

    it "should be ok if classification not found" do
      code = CharityImport::Importer.send(:classification_tag_name, '24', nil)
      code.should be_nil
    end
  end # end classification tags

  describe "activity tags" do
    it "should get activity" do
      code = CharityImport::Importer.send(:activity_tag_name, '039')
      code.should == 'Scholarships for children of employees'
    end

    it "should be ok if not found" do
      code = CharityImport::Importer.send(:activity_tag_name, nil)
      code.should be_nil
    end

    it "should handle 0" do
      code = CharityImport::Importer.send(:activity_tag_names, '0.0')
      code.should be_nil
    end

    it "should handle nil" do
      code = CharityImport::Importer.send(:activity_tag_names, nil)
      code.should be_nil
    end

    it "should work with 9 characters" do
      codes = CharityImport::Importer.send(:activity_tag_names, '179399559')
      codes.should include('Other health services')
      codes.should include('Other housing activities')
      codes.should include('Other matters')
    end

    it "should work with less than 9 characters" do
      codes = CharityImport::Importer.send(:activity_tag_names, '1000000')
      codes.should include('Church, synagogue')
      codes.should include(nil)
    end

    it "should work with float" do
      codes = CharityImport::Importer.send(:activity_tag_names, '30036382.0')
      codes.should include('Housing for the aged')
      codes.should include('Fraternity or sorority')
      codes.should include('School, college, trade school')
    end
  end # end activity tags

  describe "ntee common tags" do
    it "should handle blank" do
      code = CharityImport::Importer.send(:ntee_common_tag_name, nil)
      code.should be_nil
    end

    it "should work" do
      code = CharityImport::Importer.send(:ntee_common_tag_name, 'A23')
      code.should == 'Arts, Culture and Humanities'
    end
  end

  describe "ntee core tags" do
    it "should handle blank" do
      code = CharityImport::Importer.send(:ntee_core_tag_name, nil)
      code.should be_nil
    end

    it "should work" do
      code = CharityImport::Importer.send(:ntee_core_tag_name, 'A23')
      code.should == 'Cultural, Ethnic Awareness'
    end
  end
end
