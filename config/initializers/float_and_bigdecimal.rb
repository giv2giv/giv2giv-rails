class Float

  # Credit to http://richonrails.com/articles/rounding-numbers-in-ruby

  def floor2(exp = 0)
  	multiplier = 10 ** exp
  	((self * multiplier).floor).to_f/multiplier.to_f
  end

  def ceil2(exp = 0)
  	multiplier = 10 ** exp
  	((self * multiplier).ceil).to_f/multiplier.to_f
  end

end

class BigDecimal

  # Credit to http://richonrails.com/articles/rounding-numbers-in-ruby

  def floor2(exp = 0)
  	multiplier = 10 ** exp
  	((self * multiplier).floor).to_f/multiplier.to_f
  end

  def ceil2(exp = 0)
  	multiplier = 10 ** exp
  	((self * multiplier).ceil).to_f/multiplier.to_f
  end

end