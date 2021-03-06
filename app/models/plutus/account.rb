module Plutus
  # The Account class represents accounts in the system. Each account must be subclassed as one of the following types:
  #
  #   TYPE        | NORMAL BALANCE    | DESCRIPTION
  #   --------------------------------------------------------------------------
  #   Asset       | Debit             | Resources owned by the Business Entity
  #   Liability   | Credit            | Debts owed to outsiders
  #   Equity      | Credit            | Owners rights to the Assets
  #   Revenue     | Credit            | Increases in owners equity
  #   Expense     | Debit             | Assets or services consumed in the generation of revenue
  #
  # Each account can also be marked as a "Contra Account". A contra account will have it's
  # normal balance swapped. For example, to remove equity, a "Drawing" account may be created
  # as a contra equity account as follows:
  #
  #   Plutus::Equity.create(:name => "Drawing", contra => true)
  #
  # At all times the balance of all accounts should conform to the "accounting equation"
  #   Plutus::Assets = Liabilties + Owner's Equity
  #
  # Each sublclass account acts as it's own ledger. See the individual subclasses for a
  # description.
  #
  # @abstract
  #   An account must be a subclass to be saved to the database. The Account class
  #   has a singleton method {trial_balance} to calculate the balance on all Accounts.
  #
  # @see http://en.wikipedia.org/wiki/Accounting_equation Accounting Equation
  # @see http://en.wikipedia.org/wiki/Debits_and_credits Debits, Credits, and Contra Accounts
  #
  # @author Michael Bulat
  class Account < ActiveRecord::Base
    attr_accessible :name, :contra

    has_many :credit_amounts
    has_many :debit_amounts
    has_many :credit_transactions, :through => :credit_amounts, :source => :transaction
    has_many :debit_transactions, :through => :debit_amounts, :source => :transaction
    belongs_to :accountable, :polymorphic => true

    validates_presence_of :type, :name
    validates_uniqueness_of :name

    def credits_by_date(start_date = "1900-01-01", end_date = Date.today + 15.days)
      end_date = Date.today + 15.days if end_date.nil?
      start_date = "1900-01-01" if start_date.nil?
      credit_amounts.includes(:transaction).where("plutus_transactions.date >= '#{start_date}' AND DATE( plutus_transactions.date) <= '#{end_date.to_s}'")
    end

    def debits_by_date(start_date = "1900-01-01", end_date = Date.today + 15.days)
      end_date = Date.today + 15.days if end_date.nil?
      start_date = "1900-01-01" if start_date.nil?
      debit_amounts.includes(:transaction).where("plutus_transactions.date >= '#{start_date}' AND DATE( plutus_transactions.date ) <= '#{end_date.to_s}'")
    end

    # The trial balance of all accounts in the system. This should always equal zero,
    # otherwise there is an error in the system.
    #
    # @example
    #   >> Account.trial_balance.to_i
    #   => 0
    #
    # @return [BigDecimal] The decimal value balance of all accounts
    def self.trial_balance(startDate = nil, endDate = nil)
      if self.new.class != Account
        raise(NoMethodError, "undefined method 'trial_balance'")
      elsif startDate || endDate
        Asset.balance( startDate, endDate ) - (Liability.balance( startDate, endDate ) + Equity.balance( startDate, endDate ) + Revenue.balance( startDate, endDate ) - Expense.balance( startDate, endDate ))
      else
        Asset.balance - (Liability.balance + Equity.balance + Revenue.balance - Expense.balance)
      end
    end

  end
end
