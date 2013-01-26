module Plutus
  # The Equity class is an account type used to represents owners rights to the assets.
  #
  # === Normal Balance
  # The normal balance on Equity accounts is a *Credit*.
  #
  # @see http://en.wikipedia.org/wiki/Equity_(finance) Equity
  #
  # @author Michael Bulat
  class Equity < Account

    # The credit balance for the account.
    #
    # @example
    #   >> equity.credits_balance
    #   => #<BigDecimal:103259bb8,'0.3E4',4(12)>
    #
    # @return [BigDecimal] The decimal value credit balance
    def credits_balance( start_date = nil, end_date = nil )
      credits_balance = BigDecimal.new('0')
      if start_date || end_date
        credits_by_date( start_date, end_date ).each do |credit_amount|
          credits_balance = credits_balance + credit_amount.amount
        end
      else
        credit_amounts.each do |credit_amount|
          credits_balance = credits_balance + credit_amount.amount
        end
      end
      return credits_balance
    end

    # The debit balance for the account.
    #
    # @example
    #   >> equity.debits_balance
    #   => #<BigDecimal:103259bb8,'0.1E4',4(12)>
    #
    # @return [BigDecimal] The decimal value credit balance
    def debits_balance( start_date = nil, end_date = nil )
      debits_balance = BigDecimal.new('0')
      if start_date || end_date
        debits_by_date( start_date, end_date ).each do |debit_amount|
          debits_balance = debits_balance + debit_amount.amount
        end
      else
        debit_amounts.each do |debit_amount|
          debits_balance = debits_balance + debit_amount.amount
        end
      end
      return debits_balance
    end


    # The balance of the account.
    #
    # Equity accounts have normal credit balances, so the debits are subtracted from the credits
    # unless this is a contra account, in which credits are subtracted from debits
    #
    # @example
    #   >> asset.balance
    #   => #<BigDecimal:103259bb8,'0.2E4',4(12)>
    #
    # @return [BigDecimal] The decimal value balance
    def balance(start_date = nil, end_date = nil)
      unless contra
        (start_date.nil? && end_date.nil?) ?      
          credits_balance - debits_balance :
          credits_balance - debits_balance( start_date, end_date ) 
      else
        (start_date.nil? && end_date.nil?) ?
          debits_balance - credits_balance :
          debits_balance - credits_balance( start_date, end_date )
      end
    end

    # This class method is used to return
    # the balance of all Equity accounts.
    #
    # Contra accounts are automatically subtracted from the balance.
    #
    # @example
    #   >> Plutus::Equity.balance
    #   => #<BigDecimal:1030fcc98,'0.82875E5',8(20)>
    #
    # @return [BigDecimal] The decimal value balance
    def self.balance( start_date = nil, end_date = nil )
      accounts_balance = BigDecimal.new('0')
      accounts = self.find(:all)
      accounts.each do |equity|

        unless equity.contra
        (start_date.nil? && end_date.nil?) ?          
          accounts_balance += equity.balance :
          accounts_balance += equity.balance( start_date, end_date )

        else

        (start_date.nil? && end_date.nil?) ?
          accounts_balance -= equity.balance :
          accounts_balance -= equity.balance( start_date, end_date )

        end
      end
      accounts_balance
    end
  end
end
