FactoryGirl.define do
  sequence :ein do |n|
    if (n < 2)
      [660779435, 943566077][n]
    else
      100000000 + n
    end
  end

  factory :charity do
    ein
    sequence(:name) {|n| "Charity#{n}"}
  end
end