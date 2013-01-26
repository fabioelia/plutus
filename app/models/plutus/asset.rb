module Plutus
  # The Asset class is an account type used to represents resources owned by the business entity.
  #
  # === Normal Balance
  # The normal balance on Asset accounts is a *Debit*.
  #
  # @see http://en.wikipedia.org/wiki/Asset Assets
  #
  # @author Michael Bulat
  class Asset < Account

    # The credit balance for the account.
    #
    # @example
    #   >> asset.credits_balance
    #   => #<BigDecimal:103259bb8,'0.1E4',4(12)>
    #
    # @return [BigDecimal] The decimal value credit balance
    def credits_balance(start_date = nil, end_date = nil )
      credits_balance = BigDecimal.new('0')
      if start_date || end_date
        credits_by_date(start_date, end_date).each do |credit_amount|
          credits_balance += credit_amount.amount
        end
      else
        credit_amounts.each do |credit_amount|
          credits_balance += credit_amount.amount
        end
      end


      return credits_balance
    end

    # The debit balance for the account.
    #
    # @example
    #   >> asset.debits_balance
    #   => #<BigDecimal:103259bb8,'0.3E4',4(12)>
    #
    # @return [BigDecimal] The decimal value credit balance
    def debits_balance(start_date = nil, end_date = nil )
      debits_balance = BigDecimal.new('0')
      if start_date || end_date
        debits_by_date(start_date, end_date).each do |debit_amount|
          debits_balance += debit_amount.amount
        end
      else
        debit_amounts.each do |debit_amount|
          debits_balance += debit_amount.amount
        end
      end
      return debits_balance
    end

    # The balance of the account.
    #
    # Assets have normal debit balances, so the credits are subtracted from the debits
    # unless this is a contra account, in which debits are subtracted from credits
    #
    # @example
    #   >> asset.balance
    #   => #<BigDecimal:103259bb8,'0.2E4',4(12)>
    #
    # @return [BigDecimal] The decimal value balance
    def balance(start_date = nil, end_date = nil)
      unless contra
        (start_date.nil? && end_date.nil?) ?
          debits_balance - credits_balance :
          debits_balance(start_date,end_date) - credits_balance(start_date,end_date)
      else
        (start_date.nil? && end_date.nil?) ?
          credits_balance - debits_balance :
          credits_balance(start_date,end_date) - debits_balance(start_date,end_date)
      end
    end

    # This class method is used to return
    # the balance of all Asset accounts.
    #
    # Contra accounts are automatically subtracted from the balance.
    #
    # @example
    #   >> Plutus::Asset.balance
    #   => #<BigDecimal:1030fcc98,'0.82875E5',8(20)>
    #
    # @return [BigDecimal] The decimal value balance
    def self.balance( start_date = nil, end_date = nil )
      accounts_balance = BigDecimal.new('0')
      accounts = self.find(:all)
      accounts.each do |asset|
        unless asset.contra
          (start_date.nil? && end_date.nil?) ?        
            accounts_balance += asset.balance :
            accounts_balance += asset.balance( start_date, end_date )
        else
          (start_date.nil? && end_date.nil?) ?        
            accounts_balance -= asset.balance :
            accounts_balance -= asset.balance( start_date, end_date ) 
        end
      end
      accounts_balance
    end
  end
end
