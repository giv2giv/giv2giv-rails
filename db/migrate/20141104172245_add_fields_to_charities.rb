class AddFieldsToCharities < ActiveRecord::Migration
  def change
		add_column :charities, :care_of, :string
		add_column :charities, :group_code, :string
		add_column :charities, :affiliation_code, :string
		add_column :charities, :ruling_date, :date, :null => true
		add_column :charities, :deductibility_code, :string
		add_column :charities, :foundation_code, :string
		add_column :charities, :organization_code, :string
		add_column :charities, :status_code, :string
		add_column :charities, :tax_period, :date, :null => true
		add_column :charities, :asset_code, :string
		add_column :charities, :income_code, :string
		add_column :charities, :filing_requirement_code, :string
		add_column :charities, :pf_filing_requirement_code, :string
		add_column :charities, :accounting_period, :string
		add_column :charities, :asset_amount, :integer
		add_column :charities, :income_amount, :integer
		add_column :charities, :revenue_amount, :integer
		add_column :charities, :secondary_name, :string
		add_attachment :charities, :image
  end
end
